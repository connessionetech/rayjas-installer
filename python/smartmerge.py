import os
import shutil
import json
from urllib.request import urlopen

from jsonmerge import merge
from jsonschema import validate
from sys import argv
import argparse

import logging


# Configure the logging system
logging.basicConfig(filename ='grahil_update.log',
                    level = logging.DEBUG)


excludes=["logging.json"]


def_conf_schema = {
            "properties" : {
                "enabled": {
                    "type": "boolean",
                    "mergeStrategy": "overwrite"
                },
                "klass": {
                    "type": "string",
                    "mergeStrategy": "discard"
                },
                "conf": {
                    "type": "object",
                    "mergeStrategy": "objectMerge"
                }
            },
            "required": ["enabled", "klass", "conf"]
        }



def_rules_schema = {
            "properties" : {
                "id": {
                    "type": "string",
                    "mergeStrategy": "overwrite"
                },
                "enabled": {
                    "type": "boolean",
                    "mergeStrategy": "overwrite"
                },
                "listen-to": {
                    "type": "string",
                    "mergeStrategy": "overwrite"
                },
                "trigger": {
                    "type": "object",
                    "mergeStrategy": "objectMerge"
                },
                "response": {
                    "type": "object",
                    "mergeStrategy": "objectMerge"
                }
            },
            "required": ["id", "description", "listen-to", "enabled", "trigger", "response"]
        }

def_master_configuration_schema = {
            "properties" : {
                "configuration": {
                    "type": "object",
                    "properties" : {
                        "base_package": {
                            "type": "string",
                            "mergeStrategy": "overwrite"
                        },
                        "server": {
                            "type": "object",
                            "mergeStrategy": "objectMerge"
                        },
                        "ssl": {
                            "type": "object",
                            "mergeStrategy": "objectMerge"
                        },
                        "modules": {
                            "type": "object",
                            "mergeStrategy": "objectMerge"
                        }                 
                    },
                     "required": ["base_package", "server", "ssl", "modules"]
                }                
            },
            "required": ["configuration"]
        }



def generate_updated(latest_path:str, update_path:str, profile_package_path:str)->None:

    # Collect list of all new files (json and otherwise)
    logging.info("Collecting list of all json files to be processed")
    latest_files = []
    latest_json_files = []
    for subdir, dirs, files in os.walk(latest_path):
        for file in files:
            if not file.endswith(".json"):
                program_file = os.path.join(subdir, str(file))
                latest_files.append(program_file)
            else:
                json_file = os.path.join(subdir, str(file))
                skip = False
                
                for exclude in excludes:
                    if exclude in json_file:
                        skip = True
                        break
                
                if not skip:    
                    logging.debug("Collecting config file %s",json_file)
                    latest_json_files.append(json_file)
    

    # Collect list of applicable files inside profile package
    logging.info("Collecting list of all profile files to be processed")
    profile_script_files = []
    profile_rules_json_files = []
    profile_module_config_json_files = []
    for subdir, dirs, files in os.walk(profile_package_path):
        for file in files:
            if file.endswith(".sh") or file.endswith(".bat"):
                script_file = os.path.join(subdir, str(file))
                profile_script_files.append(script_file)
            elif file.endswith(".json"):
                json_file = os.path.join(subdir, str(file))

                if "rules/" in str(json_file):
                    logging.debug("Collecting profile rule file %s",json_file)
                    profile_rules_json_files.append(json_file)
                elif "modules/conf/" in str(json_file):
                    logging.debug("Collecting config file %s",json_file)
                    profile_module_config_json_files.append(json_file)
            

    # then we overwrite latest files on old files in updated workspace (minus json files)
    logging.info("Copying files from %s into %s", latest_path, update_path)
    for file in latest_files:
        old_file_in_update_workspace = str(file).replace(latest_path, update_path)
        logging.debug("Copying file %s to %s", old_file_in_update_workspace, file)
        dest = shutil.copy2(file, old_file_in_update_workspace)


    ## check, validate and merge json configuration files into updated woprkspace       
    logging.info("Preparing to merge json files")
    for file in latest_json_files:
        old_file_in_update_workspace = str(file).replace(latest_path, update_path)
        logging.debug("updating file %s", old_file_in_update_workspace)

        with open(old_file_in_update_workspace, 'r') as old_json_file:
            base_data = old_json_file.read()
            base_obj = json.loads(base_data)
        
            with open(file, 'r') as latest_json_file:
                latest_data = latest_json_file.read()
                latest_obj = json.loads(latest_data)

            if "conf/" in old_file_in_update_workspace:
                validate(base_obj, def_conf_schema)
                validate(latest_obj, def_conf_schema)
                updated_data = merge(latest_obj, base_obj)
            elif "rules/" in old_file_in_update_workspace:
                validate(base_obj, def_rules_schema)
                validate(latest_obj, def_rules_schema)
                updated_data = merge(latest_obj, base_obj)
            elif "configuration.json" in old_file_in_update_workspace:
                validate(base_obj, def_master_configuration_schema)
                validate(latest_obj, def_master_configuration_schema)
                updated_data = merge(latest_obj, base_obj)
            else:
                logging.warning("Unsure of how to update this file %s... skipping", str(old_json_file))
                continue

            with open(old_file_in_update_workspace, "w") as outfile:
                    outfile.write(json.dumps(updated_data))


# Create the parser
my_parser = argparse.ArgumentParser(description='Merge json configuratrion files')
my_parser.add_argument('source', metavar='path', type=str, help='Path of source directory (downloaded files workspace)')
my_parser.add_argument('destination', metavar='path', type=str, help='Path of destination directory (updated files workspace)')
my_parser.add_argument('profile', metavar='path', type=str, help='Path of profile package directory (extracted profile archive)')
args = my_parser.parse_args()
source_path = args.source
destination_path = args.destination
profile_package_path = args.profile

try:
    if not os.path.isdir(source_path) or not os.path.isdir(destination_path):
        raise Exception("One or more invalid path(s) specified")
    generate_updated(source_path, destination_path, profile_package_path)
    logging.info("Merge completed successfully!")
    print("merge ok")
except Exception as e:
    logging.error("Error occurred %s", str(e))
    print("merge error." + str(e))