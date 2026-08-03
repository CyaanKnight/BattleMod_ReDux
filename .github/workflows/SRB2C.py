'''
# SRB2ModCompiler v9.0 by Lumyni (felixlumyni on discord)
# Requires https://www.python.org/
# Messes w/ files, only edit this if you know what you're doing!
'''

import os

'''
LAZY IMPORTS: 
- argparse: Only when running the script
- subprocess, datetime and shlex: Only in the run() function
- winreg: Only in the set_environment_variable() and get_environment_variable() functions
- platform: Same as above, but also in the run and "cls" commands
- tkinter: Only in the file_explorer() and directory_explorer() functions
- io and zipfile: Only in the unzip_pk3() and create_or_update_zip() functions
- shutil: Only in the unzip_pk3() function
- re: Only in the create_versioninfo() function
- traceback: Only when there is an error in the run() function while verbose is enabled
- json: Only in the save_config() and load_config() functions
- platformdirs: Only in the get_config_path() function
- warnings: Only in the create_or_update_zip() function
- fnmatch: Only in the _is_ignored() function
- zlib: Only in the _get_file_crc() function
'''

runcount = 0
isVerbose = False
isDeflate = False

def verbose(*args, **kwargs):
    if isVerbose:
        print(*args, **kwargs)

vscode = 'TERM_PROGRAM' if 'TERM_PROGRAM' in os.environ.keys() and os.environ['TERM_PROGRAM'] == 'vscode' else ''
RED = '\033[31m' if vscode else ''
GREEN = '\033[32m' if vscode else ''
BLUE = '\033[36m' if vscode else ''
YELLOW = '\033[93m' if vscode else ''
RESETCOLOR = '\033[0m' if vscode else ''
BLACK = '\033[30m' if vscode else ''
UNDERLINE = '\033[4m' if vscode else ''
NOUNDERLINE = '\033[24m' if vscode else ''

DEFAULT_IGNORE = '''
*.py
*.pyw
*.md
LICENSE
*.ase
.*
.git/
'''

def main():
    global isVerbose
    global isDeflate

    profile, name = get_active_profile()
    status = GREEN+"ready" if profile["exe_path"] else (YELLOW+"optional" if os.name=="posix" else RED+"not set")
    
    print(BLUE, end="")
    print(f"Welcome to SRB2ModCompiler v2! Active profile '{GREEN}{name}{BLUE}' is {status}{BLUE}.")
    print(f"ENTER to begin, or type '{GREEN}help{BLUE}' to explore available commands.")
    
    while True:
        command = input(RESETCOLOR+"> ").lower().strip()
        print(BLUE, end="")

        if command == "help":
            print(f"{UNDERLINE}Essential commands:{NOUNDERLINE}")
            print(f"  {GREEN}<literally nothing>{BLUE} - Compile this script's directory into a mod and launch it in SRB2! {BLACK}(Requires a valid profile){BLUE}")
            print(f"  {GREEN}profile{BLUE} - Manage game profiles and settings")
            #print(f"  {GREEN}vars{BLUE} - List the system variable commands {BLACK}(DEPRECATED, please use profiles instead){BLUE}")
            print(f"{UNDERLINE}Extra commands:{NOUNDERLINE}")
            print(f"  {GREEN}7z{BLUE} - Like pressing Enter but uses 7-Zip for compression")
            print(f"  {GREEN}7z set{BLUE} - Set path to 7z.exe executable")
            print(f"  {GREEN}mod{BLUE} - Specify where the mod files are with a relative path file")
            print(f"  {GREEN}args{BLUE} - Update launch parameters as a file, for yourself or for the mod")
            print(f"  {GREEN}verbose{BLUE} - Toggle detailed output, useful for debugging")
            print(f"  {GREEN}unzip{BLUE} - Decompile a pk3 back into a compile-able folder")
            print(f"  {GREEN}quit{BLUE} - Exit the program")
        elif command == "vars":
            print(f"{UNDERLINE}System variable commands (DEPRECATED, please use profiles instead):{NOUNDERLINE}")
            print(f"  {GREEN}set{BLUE} - Update the system variable that points to your SRB2 executable")
            print(f"  {GREEN}downloads{BLUE} - Update the secondary system variable that determines where your pk3 files will be saved instead of always on DOWNLOAD/_srb2compiled")
            print(f"  {GREEN}path{BLUE} - Show where all system variables point to")
            print(f"  {GREEN}unset{BLUE} - Clear all system variables")
        elif command == "path":
            srb2_loc = get_environment_variable("SRB2C_LOC")
            srb2_dl = get_environment_variable("SRB2C_DL")
            print(f"SRB2C_LOC system variable path: {srb2_loc}")
            print(f"SRB2C_DL system variable path: {srb2_dl}")
        elif command == "set":
            print(f"Enter {GREEN}E{BLUE} to open the file explorer or paste the path to your SRB2 executable here.")
            command = input(RESETCOLOR+">> ")
            print(BLUE, end="")
            if command.lower().strip() == "e":
                choose_srb2_executable()
            else:
                path = sanitized_exe_filepath(command)
                if path:
                    set_environment_variable("SRB2C_LOC", path)
                    print("SRB2C_LOC system variable updated! Now just press enter to run it.")
                else:
                    print("Operation cancelled.")
        elif command == "downloads":
            print(f"Enter {GREEN}E{BLUE} to open the file explorer or paste the path of where you want your compiled mods to be saved.")
            command = input(RESETCOLOR+">> ")
            print(BLUE, end="")
            if command.lower().strip() == "e":
                choose_srb2_downloads()
            else:
                path = sanitized_directory_path(command)
                if path:
                    set_environment_variable("SRB2C_DL", path)
                    print("SRB2C_DL system variable updated!")
                else:
                    print("Operation cancelled.")
        elif command == "unset":
            set_environment_variable("SRB2C_LOC", None)
            set_environment_variable("SRB2C_DL", None)
            print("Unset SRB2C_LOC and SRB2C_DL variables.")
        elif command == "args":
            print(f"- Used to launch the game with special settings. DEFAULT: {GREEN}-skipintro{BLUE}")
            print(f'- Example: {GREEN}-skipintro -server +downloading off +color orange +skin tails +wait 1 +"map tut -g 0 -f"{BLUE}')
            print(f"{RED}- NOTE: Regardless of what parameters you type in here, the script will always use the {GREEN}-file (your_mod.pk3){RED} parameter to run your mod.")
            verbose(f"    - Use {GREEN}-prefile{RED} or {GREEN}+addfile{RED} instead to ensure there won't be addon load order conflicts.{BLUE}")
            print(f"{BLACK}- TIP: Refer to the 'command line parameters' page from the SRB2 Wiki for more parameters{BLUE}.")
            print()
            print(f"{UNDERLINE}First, where do you want to save the file?{NOUNDERLINE}")
            print(f"{GREEN}Nothing{BLUE}: Leave blank to cancel")
            print(f"{GREEN}Enter 1{BLUE}: Default directory (Will be modified for everyone in this repository)")
            print(f"{GREEN}Enter 2{BLUE}: Mod directory (Will be modified only for you, if it's on .gitignore)")

            save_location = input(RESETCOLOR+">> ").strip()
            print(BLUE, end="")
            if save_location not in ["1", "2"]:
                print("Operation cancelled.")
                continue

            print("Enter your args, or leave blank to delete the file (DEFAULT will be used by the program).")
            
            script_dir = os.path.dirname(os.path.abspath(__file__))
            mod_dir = find_mod_directory()
            filename = ".SRB2C_ARGS"
            filepath = os.path.join(script_dir if save_location == "1" else mod_dir, filename)
            basedirname = os.path.basename(os.path.dirname(filepath))

            if os.path.exists(filepath):
                with open(filepath, "r") as file:
                    existing_args = file.read().strip()
                print(f"Current args in {GREEN}{basedirname}/{filename}{BLUE}:{GREEN} {existing_args}{BLUE}")

            command = input(RESETCOLOR+">>> ").lower().strip()
            print(BLUE, end="")
            if command == "":
                if os.path.exists(filepath):
                    os.remove(filepath)
                    print(f"{filename} file was deleted.")
                else:
                    print(f"{filename} file does not exist.")
            else:
                params = command.split()
                with open(filepath, "w") as file:
                    file.write(" ".join(params))
                print(f"{filename} file was created/updated in the {'default' if save_location == '1' else 'mod'} directory!")
        elif command == "quit":
            print(RESETCOLOR, end="")
            break
        elif command == "":
            try:
                run()
            except Exception as e:
                print(f"{RED}Error: {e}")
                if isVerbose:
                    import traceback
                    traceback.print_exc()
                print(f"Double check your configuration files. If this is an internal error, please report this!{BLUE}")
        elif command == "multirun":
            print("Enter the number of instances you want to run.")
            command = input(RESETCOLOR+">> ").strip()
            print(BLUE, end="")
            try:
                command = int(command)
                try:
                    run(multiCount=command)
                except Exception as e:
                    print(f"{RED}Error: {e}")
                    if isVerbose:
                        import traceback
                        traceback.print_exc()
                    print(f"Double check your configuration files. If this is an internal error, please report this!{BLUE}")
            except ValueError:
                print("Operation cancelled due to invalid input.")
                continue
        elif command == "nothing":
            print("stop it.")
        elif command == "<literally nothing>":
            print("BRUH LOL")
            print("You know what I meant.")
        elif command == "run":
            print(BLACK+"Who are you running from?"+BLUE)
        elif command == "cls":
            import platform
            if platform.system() == 'Windows':
                os.system('cls')
            else:
                os.system('clear')
        elif command == "unzip":
            print("Enter the name of the .pk3 file to unzip, or 'e' to use file explorer:")
            command = input(RESETCOLOR+">> ").lower().strip()
            print(BLUE, end="")
            
            if command == 'e':
                print("Select a .pk3 file to unzip:")
                file_path = file_explorer([("PK3 files", "*.pk3")])
            else:
                file_path = os.path.join(os.getcwd(), command)
            
            if file_path and os.path.exists(file_path):
                output_dir = os.path.join(os.path.dirname(file_path), os.path.splitext(os.path.basename(file_path))[0])
                output = unzip_pk3(file_path, output_dir)
                if output == True:
                    print(f"{GREEN}Successfully unzipped {os.path.basename(file_path)} to {os.path.basename(output_dir)}{BLUE}")
                else:
                    print(f"{RED}Error: {output}{BLUE}")
            else:
                print("Operation cancelled. No valid file selected or found.")
        elif command == "verbose":
            isVerbose = not isVerbose
            print(f"Verbose mode is now {GREEN if isVerbose else RED}{('enabled' if isVerbose else 'disabled')}{BLUE}.")
        elif command == "deflate":
            isDeflate = not isDeflate
            print(f"Deflate mode is now {GREEN if isDeflate else RED}{('enabled' if isDeflate else 'disabled')}{BLUE}.")
        elif command == "mod":
            print("- Enter the relative path of the mod to launch. Example: ../my_mod")
            print("- Enter 'e' to use file explorer, or 'c' to delete the file and use the default (this script's directory).")
            print("- To cancel, simply press enter without typing anything")
            command = input(RESETCOLOR+">> ").lower().strip()
            print(BLUE, end="")
            if command == "":
                print("Operation cancelled by user.")
            elif command == "e":
                print("Select a mod directory:")
                mod_dir = directory_explorer()
                if mod_dir:
                    command = os.path.relpath(mod_dir, os.path.dirname(os.path.abspath(__file__)))
                else:
                    print("No directory selected. Operation cancelled.")
                    continue
            elif command == "c":
                script_dir = os.path.dirname(os.path.abspath(__file__))
                filename = ".SRB2C_MODPATH"
                filepath = os.path.join(script_dir, filename)
                if os.path.exists(filepath):
                    os.remove(filepath)
                    print(f"{filename} file has been deleted.")
                else:
                    print(f"{filename} file does not exist.")
                continue
            
            if command not in ["", "e", "c"]:
                script_dir = os.path.dirname(os.path.abspath(__file__))
                mod_dir = os.path.join(script_dir, command)
                if os.path.isdir(mod_dir):
                    filename = ".SRB2C_MODPATH"
                    filepath = os.path.join(script_dir, filename)
                    with open(filepath, "w") as file:
                        file.write(command)
                    print(filename,"file was created/updated (in the same directory as this script)!")
                    global runcount
                    runcount = 0
                else:
                    print(f"{RED}Error: The directory '{mod_dir}' does not exist.{BLUE}")
        elif command == "profile":
            print(f"{UNDERLINE}Profile commands:{NOUNDERLINE}")
            print(f"  {GREEN}profile{BLUE} - Show all profiles and which one is active")
            print(f"  {GREEN}profile add{BLUE} - Create a new game profile") 
            print(f"  {GREEN}profile switch{BLUE} - Change active profile")
            print(f"  {GREEN}profile remove{BLUE} - Delete a profile")
            print(f"  {GREEN}profile set{BLUE} - Set executable path for current profile")
            print(f"  {GREEN}profile downloads{BLUE} - Set downloads path for current profile")
        elif command == "profile add":
            print("Enter the name for the new profile:")
            name = input(RESETCOLOR+">> ").lower().strip()
            print(BLUE, end="")
            if name:
                config = load_config()
                if name in config["profiles"]:
                    print(f"{RED}Profile {name} already exists!{BLUE}")
                else:
                    config["profiles"][name] = {
                        "exe_path": "",
                        "downloads_path": ""
                    }
                    save_config(config)
                    print(f"Created new profile: {GREEN}{name}{BLUE}")
            elif command == "profile switch":
                config = load_config()
                profiles = list(config["profiles"].keys())
                print("Available profiles:")
                for i, name in enumerate(profiles, 1):
                    active = " (active)" if name == config["active_profile"] else ""
                    print(f"{GREEN}{i}{BLUE}. {name}{active}")
                print("\nEnter profile number to switch to:")
                choice = input(RESETCOLOR+">> ").strip()
                print(BLUE, end="")
                try:
                    idx = int(choice) - 1
                    if 0 <= idx < len(profiles):
                        config["active_profile"] = profiles[idx]
                        save_config(config)
                        print(f"Switched to profile: {GREEN}{profiles[idx]}{BLUE}")
                        #global runcount
                        runcount = 0
                    else:
                        print(f"{RED}Invalid profile number{BLUE}")
                except ValueError:
                    print(f"{RED}Invalid input{BLUE}")
        elif command == "profile remove":
            config = load_config()
            if len(config["profiles"]) <= 1:
                print(f"{RED}Cannot remove the last profile!{BLUE}")
                continue
            
            print("Select profile to remove:")
            profiles = list(config["profiles"].keys())
            for i, name in enumerate(profiles, 1):
                active = " (active)" if name == config["active_profile"] else ""
                print(f"{GREEN}{i}{BLUE}. {name}{active}")

            choice = input(RESETCOLOR+">> ").strip()
            print(BLUE, end="")
            try:
                idx = int(choice) - 1
                if 0 <= idx < len(profiles):
                    name = profiles[idx]
                    if name == config["active_profile"]:
                        other_profile = next(p for p in profiles if p != name)
                        config["active_profile"] = other_profile
                    del config["profiles"][name]
                    save_config(config)
                    print(f"Removed profile: {GREEN}{name}{BLUE}")
                    runcount = 0
                else:
                    print(f"{RED}Invalid profile number{BLUE}")
            except ValueError:
                print(f"{RED}Invalid input{BLUE}")
        elif command == "profile set":
            profile, name = get_active_profile()
            print(f"Setting executable path for profile: {GREEN}{name}{BLUE}")
            print(f"Enter {GREEN}E{BLUE} to open file explorer or paste the path to your executable here.")
            command = input(RESETCOLOR+">> ")
            print(BLUE, end="")
            if command.lower().strip() == "e":
                path = choose_srb2_executable()
            else:
                path = sanitized_exe_filepath(command)

            if path:
                config = load_config()
                config["profiles"][name]["exe_path"] = path
                save_config(config)
                print(f"Updated executable path for profile {GREEN}{name}{BLUE}")
        elif command == "profile downloads":
            profile, name = get_active_profile()
            print(f"Setting downloads path for profile: {GREEN}{name}{BLUE}")
            print(f"Enter {GREEN}E{BLUE} to open file explorer or paste the path where you want your compiled mods to be saved.")
            command = input(RESETCOLOR+">> ")
            print(BLUE, end="")
            if command.lower().strip() == "e":
                path = choose_srb2_downloads()
            else:
                path = sanitized_directory_path(command)

            if path:
                config = load_config()
                config["profiles"][name]["downloads_path"] = path
                save_config(config)
                print(f"Updated downloads path for profile {GREEN}{name}{BLUE}")
        elif command == "7z":
            try:
                run(use_7zip=True)
            except Exception as e:
                print(f"{RED}Error: {e}")
                if isVerbose:
                    import traceback
                    traceback.print_exc()
                print(f"Double check your configuration files. If this is an internal error, please report this!{BLUE}")
        elif command == "7z set":
            print(f"Enter {GREEN}E{BLUE} to open file explorer or paste the path to your 7-Zip executable (7z.exe)")
            command = input(RESETCOLOR+">> ")
            print(BLUE, end="")
            if command.lower().strip() == "e":
                file_types = [("7-Zip executable", "7z.exe")]
                path = file_explorer(file_types)
            else:
                path = sanitized_exe_filepath(command)

            if path:
                config = load_config()
                config["7z_path"] = path
                save_config(config)
                print(f"7-Zip path updated successfully!")
        elif command == "enter":
            print("dude.")
        elif command == "ignore":
            print(f"- Used to ignore files and directories when compiling the mod with gitignore syntax... mostly.")
            print(f"DEFAULT: {GREEN}{DEFAULT_IGNORE}{BLUE}")
            print()
            print(f"{UNDERLINE}First, where do you want to save the file?{NOUNDERLINE}")
            print(f"{GREEN}Nothing{BLUE}: Leave blank to cancel")
            print(f"{GREEN}Enter 1{BLUE}: Default directory (Will be modified for everyone in this repository)")
            print(f"{GREEN}Enter 2{BLUE}: Mod directory (Will be modified only for you, if it's on .gitignore)")

            save_location = input(RESETCOLOR+">> ").strip()
            print(BLUE, end="")
            if save_location not in ["1", "2"]:
                print("Operation cancelled.")
                continue

            print("Enter your args, or leave blank to delete the file (DEFAULT will be used by the program).")
            
            script_dir = os.path.dirname(os.path.abspath(__file__))
            mod_dir = find_mod_directory()
            filename = ".SRB2C_IGNORE"
            filepath = os.path.join(script_dir if save_location == "1" else mod_dir, filename)
            basedirname = os.path.basename(os.path.dirname(filepath))

            if os.path.exists(filepath):
                with open(filepath, "r") as file:
                    existing_ignore = file.read().strip()
                print(f"Current contents of {GREEN}{basedirname}/{filename}{BLUE}:{GREEN} {existing_ignore}{BLUE}")

            command = input(RESETCOLOR+">>> ").lower().strip()
            print(BLUE, end="")
            if command == "":
                if os.path.exists(filepath):
                    os.remove(filepath)
                    print(f"{filename} file was deleted.")
                else:
                    print(f"{filename} file does not exist.")
            else:
                params = command.split()
                with open(filepath, "w") as file:
                    file.write(" ".join(params))
                print(f"{filename} file was created/updated in the {'default' if save_location == '1' else 'mod'} directory!")
        else:
            print(f"Invalid command. Type '{GREEN}help{BLUE}' to see available commands.")

def find_mod_directory():
    mod_dir = os.path.dirname(__file__)
    srb2c_modpath = os.path.join(mod_dir, '.SRB2C_MODPATH')

    if os.path.exists(srb2c_modpath):
        with open(srb2c_modpath, 'r') as f:
            relative_path = f.read().strip()
    
            new_mod_dir = os.path.normpath(os.path.join(mod_dir, relative_path))
    
            if os.path.exists(new_mod_dir) and os.path.isdir(new_mod_dir):
                return new_mod_dir
            else:
                print(f"{YELLOW}Warning: Path in .SRB2C_MODPATH is invalid. Defaulting to the original directory.{BLUE}")
    
    return mod_dir

def run(isGUI=None, multiCount=0, use_7zip=False):
    """
    I'm adding this comment because this function does a lot of things:
    - Requires the enviroment variable ``SRB2C_LOC``, which points to the user's SRB2 executable (or the SRB2 flatpak if available).
    - Optionally reads the ``.SRB2C_VERSIONINFO`` file (in the same directory as this script) and generate a file based on it.
    - Optionally reads the ``.SRB2C_ARGS`` file (first in mod, then in the same directory as this script). Defaults to ``-skipintro``
    - Optionally zips the current directory in the ``SRB2C_DL`` enviroment variable. Otherwise, defaults to``SRB2C_LOC/DOWNLOAD/_srb2compiled``
    - Runs the SRB2 executable in ``SRB2C_LOC``, with the ``-file`` parameter to run it
    - Also prints information that may be useful such as runcount and datetime
    """
    import subprocess
    import datetime
    import shlex
    global runcount

    profile, profile_name = get_active_profile()
    mod_dir = find_mod_directory()
    basedirname = os.path.basename(mod_dir)
    pk3name = "_"+basedirname+".pk3"

    # Warn if the directory doesn't look like a mod
    if runcount == 0:
        current_dir_contents = os.listdir(mod_dir)
        COMMON_SRB2_PARTS = ['Lua', 'Sprites', 'Skins', 'Textures', 'Sounds', 'Graphics', 'SOC']
        found_parts = [part for part in COMMON_SRB2_PARTS if part in current_dir_contents]

        verbose(current_dir_contents)

        if len(found_parts) < 3:
            proceed = True
            if isGUI:
                from tkinter import messagebox
                proceed = messagebox.askyesno(
                    title=f"Warning in directory: {basedirname}",
                    message=(f"The directory you're trying to compile probably isn't the mod's files! "
                             f"Less than 3 common SRB2 parts (Lua, Sprites, SOC...) were found in the current directory. "
                             f"Are you sure you want to proceed here?"),
                    icon='warning'
                    )
            if not proceed:
                print("Operation cancelled.")
                return
            elif not isGUI:
                print(f"{YELLOW}Warning: The directory you're trying to compile ({basedirname}) probably isn't the mod's files! Less than 3 common SRB2 parts (Lua, Sprites, SOC...) were found in the current directory.{BLUE}")
                verbose(f"Found parts: {', '.join(found_parts) if found_parts else 'None.'}")
                proceed = input(f"{YELLOW}Are you sure you want to proceed here? (y/n): {RESETCOLOR}").lower().strip()
                if proceed != 'y':
                    print(f"{BLUE}Operation cancelled.")
                    return
                else:
                    print(BLUE, end="")
    
    srb2_loc = profile["exe_path"]
    srb2_dl = profile["downloads_path"]

    # Check for Flatpak if no executable is set
    if not srb2_loc:
        flatpak_info = check_flatpak_availability()
        if flatpak_info["available"]:
            srb2_loc = "flatpak run org.srb2.SRB2"
            srb2_dl = os.path.join(
                os.path.expanduser("~/.var/app/org.srb2.SRB2"),
                ".srb2", "addons", "_srb2compiled"
            )
            if runcount == 0:
                print(f"{GREEN}No executable set for profile, using Flatpak SRB2...{BLUE}")
        else:
            print(f"{RED}No executable set for profile '{GREEN}{profile_name}{RED}'. Please run '{GREEN}profile set{RED}' to set it.")
            return

    if not srb2_dl:
        srb2_dl = os.path.join(
            os.path.dirname(srb2_loc) if not srb2_loc.startswith("flatpak") else srb2_loc,
            "DOWNLOAD", "_srb2compiled"
        )

    # Handle versioninfo
    try:
        create_versioninfo(datetime, subprocess)
    except Exception as e:
        if isGUI:
            raise e
        else:
            print(f"Error creating .SRB2C_VERSIONINFO file: {e}")

    # Handle args
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") # NOW! *thunder*
    gonnarun = True
    try:
        fileInModDir = True
        args_file = os.path.join(mod_dir, ".SRB2C_ARGS")
        if not os.path.exists(args_file):
            fileInModDir = False
            args_file = os.path.join(os.path.dirname(__file__), ".SRB2C_ARGS")

        with open(args_file, "r") as file:
            args_content = file.read()
            extraargs = shlex.split(args_content)
            if runcount == 0:
                if isVerbose:
                    where = os.path.basename(os.path.dirname(mod_dir if fileInModDir else os.path.dirname(__file__)))
                    verbose(f"[{now}] Found {GREEN}.SRB2C_ARGS{BLUE} file in {where}")
    except FileNotFoundError:
        if runcount == 0:
            verbose(f"[{now}] {GREEN}.SRB2C_ARGS{BLUE} file not found, so we will be using the default parameter: {GREEN}-skipintro{BLUE}")
        extraargs = ["-skipintro"]

    prefiles = []
    if "-prefile" in extraargs:
        prefile_index = extraargs.index("-prefile")
        if prefile_index + 1 < len(extraargs):
            prefiles.append(extraargs[prefile_index + 1])
            extraargs = extraargs[:prefile_index] + extraargs[prefile_index + 2:]
        else:
            print("Warning: -prefile parameter is present but no file specified. Ignoring -prefile.")

    args = [srb2_loc, "-file", pk3name]
    args.extend(extraargs)

    # Zip the project into a pk3!
    if runcount == 0:
        print(f"- Zipping '{GREEN}{basedirname}{BLUE}', please wait a moment...")

    if use_7zip:
        config = load_config()
        if not config["7z_path"]:
            print(f"7-Zip path not set. Please run '{GREEN}7z set{BLUE}' first.")
            return
            
        zip_path = os.path.join(srb2_dl, pk3name)
        subprocess.run([
            config["7z_path"],
            "a", "-tzip",
            "-mx=9",  # Maximum compression
            zip_path,
            os.path.join(mod_dir, "*"),
            "-x!*.py", "-x!*.pyw", "-x!*.md", "-x!LICENSE",
            "-x!*.ase", "-x!.git*", "-x!.*"
        ])
    else:
        filesize = create_or_update_zip(mod_dir, srb2_dl, pk3name, "DEFLATE" if isDeflate else "STORED")
        if runcount == 0 and filesize is not None and filesize > 10 * 1024 * 1024 and not isDeflate:
            print(f"{YELLOW}Warning: The compiled pk3 file is larger than 10MB. This may cause issues when sharing in certain platforms.")
            print(f"Consider deleting the pk3 and using the '{GREEN}deflate{YELLOW}' or '{GREEN}7z{YELLOW}' option for better compression.{BLUE}")

    if os.path.exists(os.path.join(srb2_dl, pk3name)):
        if runcount == 0:
            specified = "specified" if get_environment_variable("SRB2C_DL") else "SRB2's DOWNLOAD/_srb2compiled"
            print(f"- '{GREEN}"+pk3name+f"{BLUE}' (The contents of this script's directory) was created/updated in your {specified} directory")
            print("- Running SRB2 with that mod. Happy testing!")
        else:
            print(f"[{now}] Running test #{runcount+1}...")
    else:
        print(f"{RED}ERROR:{BLUE} Pk3 not detected, maybe I don't have file writing permissions?")
        gonnarun = False
    
    # Finally, let's launch the game, with the mod
    if gonnarun:
        is_flatpak = srb2_loc.startswith("flatpak")
        cwd = srb2_dl if is_flatpak else os.path.dirname(srb2_loc)

        if multiCount > 0:
            files = ["-file"]
            files.extend(prefiles)
            files.append(pk3name)

            # First launch dedicated server
            server_args = srb2_loc.split() + files + extraargs + ["-dedicated"]
            subprocess.Popen(server_args, cwd=cwd)
            
            # Launch client instances
            for _ in range(multiCount):
                client_args = srb2_loc.split() + files + extraargs
                if "-server" in client_args:
                    client_args.pop(client_args.index("-server"))
                if "-warp" in client_args:
                    warp_index = client_args.index("-warp")
                    client_args.pop(warp_index)
                    if warp_index + 1 < len(client_args):
                        client_args.pop(warp_index + 1)
                client_args.extend(["+connect", "localhost"])
                subprocess.Popen(client_args, cwd=cwd)
        else:
            # Normal single instance launch
            files = ["-file"]
            files.extend(prefiles)
            files.append(pk3name)
            args = srb2_loc.split() + files + extraargs
            process = subprocess.Popen(args, cwd=cwd,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                       universal_newlines=True, bufsize=1, errors="replace")

            for line in process.stdout:
                line = line.strip()
                if any(keyword in line for keyword in ['ERROR']):
                    print(f"{RED}{line}{BLUE}")
                elif any(keyword in line for keyword in ['WARNING']):
                    if any(keyword in line for keyword in ['multicast']):
                        pass
                    else:
                        print(f"{YELLOW}{line}{BLUE}")
                        
            process.wait()

        runcount = runcount + 1

def check_flatpak_availability():
    """Check if SRB2 Flatpak is available on the system."""
    import sys
    sys.dont_write_bytecode = True
    import shutil
    import subprocess

    result = {
        "available": False
    }

    if not sys.platform.startswith("linux"):
        return result

    if not shutil.which("flatpak"):
        return result

    try:
        flatpak_check = subprocess.run(
            ["flatpak", "list", "--app", "--columns=application"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        if "org.srb2.SRB2" in flatpak_check.stdout:
            result["available"] = True
    except Exception:
        pass

    return result

def get_environment_variable(variable: str):
    import platform
    sysvar = os.getenv(variable)

    if platform.system() == "Windows":
        import winreg
        # On Windows, manually refresh os.environ after modifying the registry
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 'Environment', 0, winreg.KEY_READ)
        try:
            sysvar, _ = winreg.QueryValueEx(key, variable)
        except FileNotFoundError:
            pass
        finally:
            winreg.CloseKey(key)
    else:
        if sysvar is not None:
            return sysvar

        shell_config_file = os.path.expanduser("~/.bashrc")  # Modify if you're using a different shell
        try:
            with open(shell_config_file, "r") as file:
                lines = file.readlines()
                for line in lines:
                    if line.startswith(f"export {variable}="):
                        # Extract value from the line, e.g., export MY_VAR="value"
                        return line.split('=')[1].strip().strip('"')
        except FileNotFoundError:
            return None

    return sysvar

def set_environment_variable(variable, value):
    import platform
    
    if platform.system() == "Windows":
        import winreg
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 'Environment', 0, winreg.KEY_SET_VALUE)
        winreg.SetValueEx(key, variable, 0, winreg.REG_EXPAND_SZ, value)
        winreg.CloseKey(key)
    else:
        shell_config_file = os.path.expanduser("~/.bashrc")
        
        with open(shell_config_file, "r") as file:
            lines = file.readlines()
        
        new_lines = [line for line in lines if not line.startswith(f"export {variable}=")]
        
        if value is not None:
            new_lines.append(f"export {variable}={value}\n")
            
        with open(shell_config_file, "w") as file:
            file.writelines(new_lines)

        os.system(f". {shell_config_file}")

def choose_srb2_executable():
    file_types = [("Executable files", "*.exe")]
    exe_path = file_explorer(file_types)
    
    if exe_path:
        path = sanitized_exe_filepath(exe_path)
        if path:
            return path
    return None

def choose_srb2_downloads():
    downloads_path = directory_explorer()
    
    if downloads_path:
        path = sanitized_directory_path(downloads_path)
        if path:
            return path
    return None


def file_explorer(file_types: list):
    from tkinter import filedialog, Tk

    root = Tk()
    root.withdraw()
    root.attributes('-topmost', True)

    file_path = filedialog.askopenfilename(filetypes=file_types)

    root.destroy()

    return file_path

def directory_explorer():
    from tkinter import filedialog, Tk

    root = Tk()
    root.withdraw()
    root.attributes('-topmost', True)

    directory_path = filedialog.askdirectory()

    root.destroy()

    return directory_path

def _parse_lines(handle):
    patterns = []
    for raw_line in handle:
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        patterns.append(line)
    return patterns

def _load_ignore_patterns(ignore_file):
    if not ignore_file:
        return []

    if hasattr(ignore_file, 'read'):
        return _parse_lines(ignore_file)

    if not os.path.isfile(ignore_file):
        verbose(f"Ignore file '{ignore_file}' was not found, skipping ignore rules.")
        return []

    with open(ignore_file, 'r', encoding='utf-8') as handle:
        return _parse_lines(handle)

def _is_ignored(rel_path: str, patterns):
    import fnmatch

    normalized_path = rel_path.replace(os.sep, '/')
    ignored = False

    for pattern in patterns:
        negate = pattern.startswith('!')
        rule = pattern[1:] if negate else pattern
        if not rule:
            continue

        if rule.endswith('/'):
            directory_rule = rule.rstrip('/')
            matches = (
                normalized_path == directory_rule
                or normalized_path.startswith(directory_rule + '/')
            )
        else:
            matches = (
                fnmatch.fnmatchcase(normalized_path, rule)
                or fnmatch.fnmatchcase(os.path.basename(normalized_path), rule)
                or rule in normalized_path.split('/')
            )

        if matches:
            ignored = not negate

    return ignored


def _get_file_crc(file_path: str) -> int:
    import zlib

    crc_value = 0
    with open(file_path, 'rb') as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            crc_value = zlib.crc32(chunk, crc_value)
    return crc_value & 0xFFFFFFFF


def create_or_update_zip(source_path: str, destination_path: str, zip_name: str, extra: str = "DEFLATED"):
    '''
    This function aims to create or update a zip file using as least write operations as possible.
    SSD health is important when you're zipping a large tree frequently.
    NEW: Also supports ignore patterns from a file, similar to .gitignore.
    '''
    import io
    import zipfile
    zip_full_path = os.path.join(destination_path, zip_name)
    compressionmethod = zipfile.ZIP_STORED if extra.upper() == "STORED" else zipfile.ZIP_DEFLATED
    ignore_file = None

    if not extra == "IGNORE-IGNORES":
        try:
            mod_dir = find_mod_directory()
            fileInModDir = True
            ignore_file = os.path.join(mod_dir, ".SRB2C_IGNORE")
            if not os.path.exists(ignore_file):
                fileInModDir = False
                ignore_file = os.path.join(os.path.dirname(__file__), ".SRB2C_IGNORE")

            with open(ignore_file, "r") as file:
                if isVerbose:
                    where = os.path.basename(os.path.dirname(mod_dir if fileInModDir else os.path.dirname(__file__)))
                    verbose(f"Found {GREEN}.SRB2C_IGNORE{BLUE} file in {where}")
        except FileNotFoundError:
            verbose(f"{GREEN}.SRB2C_IGNORE{BLUE} file not found, so we will be using the default parameters: {GREEN}{DEFAULT_IGNORE}{BLUE}")
            ignore_file = io.StringIO(DEFAULT_IGNORE)

    ignore_patterns = _load_ignore_patterns(ignore_file)
    
    # Check if the destination zip file already exists
    if os.path.exists(zip_full_path):
        import warnings

        verbose(f"Zip file '{zip_name}' already exists, updating it...")
        # Read the existing zip file into memory
        with open(zip_full_path, 'rb') as existing_zip_file:
            existing_zip_data = io.BytesIO(existing_zip_file.read())
        # Create a temporary in-memory zip file
        temp_zip_data = io.BytesIO()

        with warnings.catch_warnings():
            warnings.simplefilter('ignore')

            # Compare source files with existing zip contents
            with zipfile.ZipFile(existing_zip_data, 'r') as existing_zip, \
                zipfile.ZipFile(temp_zip_data, 'w', compression=compressionmethod) as temp_zip:

                existing_entries = {info.filename: info for info in existing_zip.infolist()}

                # Process the source directory
                verbose("Processing source directory...")
                for root, dirs, files in os.walk(source_path, topdown=True):
                    dirs.sort()
                    files.sort()

                    rel_root = os.path.relpath(root, source_path)
                    pruned_dirs = []
                    for dir_name in dirs:
                        dir_rel_path = os.path.join(rel_root, dir_name) if rel_root != '.' else dir_name
                        if _is_ignored(dir_rel_path.replace(os.sep, '/'), ignore_patterns):
                            verbose(f"Skipping ignored directory: {dir_rel_path}")
                            continue
                        pruned_dirs.append(dir_name)
                    dirs[:] = pruned_dirs

                    for file in files:
                        source_file_path = os.path.join(root, file)
                        rel_path = os.path.relpath(source_file_path, source_path).replace(os.sep, '/')

                        # Exclude unwanted files
                        if _is_ignored(rel_path, ignore_patterns):
                            continue

                        existing_info = existing_entries.get(rel_path)
                        source_size = os.path.getsize(source_file_path)

                        if existing_info is not None and source_size == existing_info.file_size:
                            source_crc = _get_file_crc(source_file_path)
                            if source_crc == existing_info.CRC:
                                verbose(f"Keeping unchanged file: {rel_path}")
                                with existing_zip.open(existing_info) as existing_entry:
                                    temp_zip.writestr(existing_info, existing_entry.read())
                                continue

                        # Read source file data for modified or new files
                        with open(source_file_path, 'rb') as source_file:
                            source_file_data = source_file.read()

                        if existing_info is not None:
                            verbose(f"Updating modified file: {rel_path}")
                        else:
                            verbose(f"Adding new file: {rel_path}")
                        temp_zip.writestr(rel_path, source_file_data)

        # Update the destination zip file with the modified contents
        verbose("Updating the destination zip file...")
        with open(zip_full_path, 'wb') as updated_zip_file:
            updated_zip_file.write(temp_zip_data.getvalue())
        verbose(f"Zip file '{zip_name}' updated successfully!")
        return os.path.getsize(zip_full_path)
    else:
        verbose(f"Zip file '{zip_name}' does not exist, creating a new one...")
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(zip_full_path), exist_ok=True)
        
        # If the destination zip file doesn't exist, create a new one
        with zipfile.ZipFile(zip_full_path, 'w', compression=compressionmethod) as new_zip:
            verbose("Processing source directory and adding files to the new zip...")
            for root, dirs, files in os.walk(source_path, topdown=True):
                dirs.sort()
                files.sort()

                rel_root = os.path.relpath(root, source_path)
                pruned_dirs = []
                for dir_name in dirs:
                    dir_rel_path = os.path.join(rel_root, dir_name) if rel_root != '.' else dir_name
                    if _is_ignored(dir_rel_path.replace(os.sep, '/'), ignore_patterns):
                        verbose(f"Skipping ignored directory: {dir_rel_path}")
                        continue
                    pruned_dirs.append(dir_name)
                dirs[:] = pruned_dirs

                for file in files:
                    source_file_path = os.path.join(root, file)
                    rel_path = os.path.relpath(source_file_path, source_path).replace(os.sep, '/')
                    # Exclude unwanted files
                    if not _is_ignored(rel_path, ignore_patterns):
                        new_zip.write(source_file_path, rel_path)
        verbose(f"New zip file '{zip_name}' created successfully!")
        return os.path.getsize(zip_full_path)

def sanitized_exe_filepath(user_input):
    path = os.path.normpath(user_input)
    real_path = os.path.realpath(path)
    is_executable = False

    if not os.path.exists(real_path):
        print(f"{RED}ERROR: The path does not exist.{BLUE}")
        return False
    else:
        if os.path.isfile(real_path):
            verbose("INFO: The path points to a file.")
            if os.path.splitext(real_path)[1] == ".exe" or os.access(real_path, os.X_OK):
                is_executable = True
        elif os.path.isdir(real_path):
            print(f"{RED}ERROR: The path points to a directory.{BLUE}")
            return False
        else:
            print(f"{RED}ERROR: The path is not a file or a directory.{BLUE}")
            return False
    
    if not is_executable:
        print(f"{RED}WARNING!! THE PATH U JUST SET DOES NOT APPEAR TO POINT TO AN EXE FILE, THE PROGRAM MIGHT SHIT ITSELF!!{BLUE}")

    return path

def sanitized_directory_path(user_input):
    path = os.path.normpath(user_input)
    real_path = os.path.realpath(path)

    if not os.path.exists(real_path):
        print(f"{RED}ERROR: The path does not exist.{BLUE}")
        return False
    else:
        if os.path.isfile(real_path):
            print("ERROR: The path points to a file.")
            return False
        elif os.path.isdir(real_path):
            print(f"INFO: The path points to a directory.")
        else:
            print(f"{RED}ERROR: The path is not a file or a directory.{BLUE}")
            return False

    return path

def remove_empty_folders(path):
    for root, dirs, files in os.walk(path, topdown=False):
        for dir in dirs:
            dir_path = os.path.join(root, dir)
            if not os.listdir(dir_path):
                os.rmdir(dir_path)
                verbose(f"Removed empty folder: {dir_path}")

def unzip_pk3(zip_path, extract_to):
    import zipfile
    import shutil
    output_dir = os.path.join(os.path.dirname(zip_path), os.path.splitext(os.path.basename(zip_path))[0])
    
    if os.path.exists(output_dir):
        response = input(f"{os.path.basename(output_dir)} already exists. Would you like to delete it? (Y/N): ").strip().lower()
        if response == 'y':
            shutil.rmtree(output_dir)
            print(f"Deleted existing directory: {output_dir}")
        else:
            print("Operation cancelled.")
            return False

    print("Unzipping... (might take a bit if your mod is large!)")

    if not os.path.exists(extract_to):
        os.makedirs(extract_to)
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        current_skin = None
        current_super = False
        
        for file_info in zip_ref.infolist():
            try:
                current_skin, current_super = organize_and_extract(file_info, zip_ref, extract_to, current_skin, current_super, shutil)
            except Exception as e:
                return f"Error extracting {file_info.filename}: {str(e)}"
    return True

def organize_and_extract(file_info, zip_ref, base_folder, current_skin, current_super, shutil):
    file_name = file_info.filename
    path_parts = file_name.split('/')
    
    if file_name.endswith('/'):
        os.makedirs(os.path.join(base_folder, file_name), exist_ok=True)
        verbose(f"Created directory: {file_name}")
        return current_skin, current_super

    if current_skin and not file_name.startswith(current_skin + '/'):
        skin_path = os.path.join(base_folder, current_skin)
        remove_empty_folders(skin_path)
        current_skin = None
        current_super = False

    if 'S_SKIN' in file_name:
        skin_dir = os.path.dirname(file_name)
        has_valid_file = any(f.lower().endswith(('.lmp', '.png')) for f in zip_ref.namelist() if os.path.dirname(f) == skin_dir)
        if has_valid_file:
            current_skin = path_parts[0]
            current_super = False
            print(f"Organizing skin folder: {skin_dir}")
        else:
            print(f"Could not organize skin folder {skin_dir}: Might already be organized.")

    
    if current_skin and file_name.startswith(current_skin):
        if 'S_SKIN' in file_name:
            category = os.path.join(current_skin, '1-S_SKIN')
        elif 'S_SUPER' in file_name:
            current_super = True
            category = os.path.join(current_skin, '3-SuperSkin', '1-S_SUPER')
        elif 'S_END' in file_name:
            category = os.path.join(current_skin, '3-SuperSkin', '3-S_END')
            current_super = False
        elif current_super:
            category = os.path.join(current_skin, '3-SuperSkin', '2-SuperSprites')
        else:
            category = os.path.join(current_skin, '2-Sprites')
        
        # Preserve subfolder structure
        subfolder_path = os.path.dirname(file_name[len(current_skin)+1:])
        category = os.path.join(category, subfolder_path)
    else:
        current_skin = None
        current_super = False
        category = os.path.dirname(file_name)
    
    destination_dir = os.path.join(base_folder, category)
    os.makedirs(destination_dir, exist_ok=True)
    
    extracted_file_path = os.path.join(destination_dir, os.path.basename(file_name))
    
    with zip_ref.open(file_info) as source, open(extracted_file_path, 'wb') as target:
        shutil.copyfileobj(source, target)
    
    verbose(f"Extracted: {file_name} to {category}")
    return current_skin, current_super

def create_versioninfo(datetime, subprocess):
    import re
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mod_dir = find_mod_directory()
    input_file = os.path.join(mod_dir, ".SRB2C_VERSIONINFO")

    if not os.path.exists(input_file):
        input_file = os.path.join(script_dir, ".SRB2C_VERSIONINFO")
        if not os.path.exists(input_file):
            verbose("No .SRB2C_VERSIONINFO file found in the mod or default directory. Skipping version info generation.")
            return

    with open(input_file, 'r') as file:
        lines = file.readlines()
    
    if not lines:
        verbose(".SRB2C_VERSIONINFO file is empty. Skipping version info generation.")
        return

    relative_path = lines[0].strip()

    if not relative_path or relative_path.startswith('/') or '..' in relative_path or ':' in relative_path:
        raise ValueError("Invalid version info file path! The first line of .SRB2C_VERSIONINFO should be a simple filepath like 'Lua/VersionInfo.lua'")

    output_file = os.path.join(mod_dir, relative_path)

    content = ''.join(lines[1:])

    # Replace special strings
    now = datetime.datetime.now()
    content = content.replace("$DATE", now.strftime("%Y-%m-%d"))
    content = content.replace("$TIME", now.strftime("%H:%M:%S"))

    fetch_pattern = r'\$FETCH:([^:]+):([^:\n]+)'
    matches = re.findall(fetch_pattern, content)
    for file_name, variable in matches:
        file_paths = [
            os.path.join(script_dir, file_name),
            os.path.join(mod_dir, file_name),
            os.path.join(os.path.dirname(mod_dir), file_name)
        ]
        file_found = False
        for file_path in file_paths:
            if os.path.exists(file_path):
                with open(file_path, 'r') as fetch_file:
                    file_content = fetch_file.read()
                    value = re.search(f'{variable}(.+)', file_content)
                    if value:
                        content = content.replace(f'$FETCH:{file_name}:{variable}', value.group(1))
                    else:
                        content = content.replace(f'$FETCH:{file_name}:{variable}', '"value_not_found"')
                file_found = True
                break
        if not file_found:
            content = content.replace(f'$FETCH:{file_name}:{variable}', '"file_not_found"')
            verbose(f"$FETCH: File {file_name} not found in script_dir, mod_dir, or mod_dir parent directory")

    try:
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).decode().strip()
        content = content.replace("$BRANCH", branch)
    except:
        content = content.replace("$BRANCH", "unknown")

    try:
        commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode().strip()
        content = content.replace("$COMMIT", commit)
    except:
        content = content.replace("$COMMIT", "unknown")

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as file:
        file.write(content)

    verbose(f"Version info file created at: {output_file}")

def get_config_path():
    from platformdirs import user_config_dir # type: ignore
    config_dir = user_config_dir("srb2modcompiler", "Lumyni")
    os.makedirs(config_dir, exist_ok=True)
    return os.path.join(config_dir, "config.json")

def load_config():
    import json
    config_path = get_config_path()
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    
    # Default config structure
    return {
        "profiles": {
            "srb2": {
                "exe_path": get_environment_variable("SRB2C_LOC") or "",
                "downloads_path": get_environment_variable("SRB2C_DL") or ""
            }
        },
        "active_profile": "srb2",
        "7z_path": ""
    }

def save_config(config):
    import json
    config_path = get_config_path()
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=4)

def get_active_profile():
    config = load_config()
    active_name = config["active_profile"]
    return config["profiles"][active_name], active_name


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Process some launch parameters.")
    parser.add_argument('-zip', nargs=4, type=str, help="Skips interface and zips given path with the given name and export path")

    args = parser.parse_args()

    if args.zip:
        create_or_update_zip(args.zip[0], args.zip[1], args.zip[2], args.zip[3])
    else:
        main()