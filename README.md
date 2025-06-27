# LandscapeLab
![vegetation-collage-small-white](https://github.com/user-attachments/assets/81130a50-b326-43bb-814d-829b8999a49d)

## Setup

* Get the [latest Geodot build for your platform](https://github.com/boku-ilen/geodot-plugin/actions) and copy the `addons/geodot` folder into this project
* Copy Setup/configuration.ini to configuration.ini in the `user://` path (`AppData` on Windows, `.local/share` on Linux) and adapt the GeoPackage path
    * On Linux, you can also use `Setup/setup_linux.sh` for this
* Open the Godot project 
* Run the main scene

We currently don't provide an executable runtime package.

### Using the optional Python features

1. Install the _PythonScript_ addon from the Godot Assetlib (the tab next to _2D_, _3D_ and _Script_)
2. Run ensurepip in the installed Python environment (on Linux: `addons/pythonscript/x11-64/bin/python3.8 -m ensurepip`)
3. Install the requirements: `addons/pythonscript/x11-64/bin/python3.8 -m pip install -r Python/requirements.txt`

## Credits

A build of our [Geodot plugin](https://github.com/boku-ilen/geodot-plugin) is included, along with the required GDAL library. All credits for GDAL go to [OSGeo/gdal](https://github.com/OSGeo/gdal/) ([license](https://raw.githubusercontent.com/OSGeo/gdal/master/gdal/LICENSE.TXT)).
