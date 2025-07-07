# LandscapeLab
![vegetation-collage-small-white](https://github.com/user-attachments/assets/81130a50-b326-43bb-814d-829b8999a49d)

The LandscapeLab (LL) is an immersive 3D visualization tool based entirely on geospatial data. Instead of streaming data in a proprietary format - like most modern 3D digital twins do -, we use our custom GDNative plugin [Geodot](https://github.com/boku-ilen/geodot-plugin) for performant loading of local data in common geospatial formats. As the required data quickly scales to extensive amounts for large areas, we usually cut data to a certain extent (~60GB for ~80x80km extents). However, in theory, you could harness the LL to visualize the entire world.

We mostly use the tool for "participatory planning" in workshop-environments. Thus, we additionally provide a 2D map interface and game-logic based on geodata, which may be based on the same data as the 3D visualization. Changes, adjustments and new planings in the 2D interface may in turn be directly reflected in the 3D tool or game-logic and vice versa.

## Project Structure and Philosophy

Our philosophy was to make the visualization-concepts as re-usable as possible. Instead of creating a new rendering logic for each visualization part and type of asset, we abstracted many concepts into the most fundamental building block of the LL: `LayerComposition`s (see [LayerCompositions.gd &rarr; `const RENDER_INFOS`](https://github.com/boku-ilen/landscapelab/blob/master/Layers/LayerComposition.gd)). Once loaded (deserialized) from a  configuration, each `LayerComposition` instantiates a 3D-renderer and UI-elements.

Most importantly, the `RealisticTerrain` and `Vegetation` need to be used to get a bare landscapelab. Additionally, buildings, trees, roads, power-lines, fences and any other 3D-asset based on point data may be added.

### Which Data, which Renderer?

Most people using this tool will be familiar with this distinction: On a high level, in GIS, we seperate between raster and vector data - continous grids of pixels vs. vertices and paths in a coordinate system.

For raster-data the LL (mainly) uses:
- Digital Terrain Model (DTM) &rarr; serves as the `y`-coordinate for terrain, assets, ...)
- normalized Digital Surface Model (nDSM; difference of DSM - DTM) &rarr; finding the height of whatever is on top of the bare terrain
- Landuse &rarr; defines terrain-textures and vegetation at the location

Vector data is further divided into one of the following:
- Point Data &rarr; usually used to place assets at the desired location, e.g. trees, wind-turbines, ... 
- Line Data &rarr; place objects along lines (repeating objects; e.g. fences), "stretch" objects on a line (line object; e.g. streets), define connected objects (e.g. power-lines; each vertex is a pole which are subsequently connected with cables)
- Polygon Data &rarr; buildings

Summarized in a table:

| data type                        | renderers that consume it                                                                                                                                                                                                                                                                                                                                          | how the data are used inside the renderer                                                                                                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **DTM** (ground elevation)       | • `BasicTerrainRenderInfo` ( `height_layer` )<br>• `RealisticTerrainRenderInfo` ( `height_layer` )<br>• `VegetationRenderInfo` / `VectorVegetationRenderInfo` ( `height_layer` )<br>• `ObjectRenderInfo` family – `Object`, `WindTurbine`, `ConnectedObject`, `RepeatingObject`, `PolygonObject` ( `ground_height_layer` )<br>• `BuildingRenderInfo` ( `ground_height_layer` ) | Forms the base terrain mesh, supplies z-values for draping vectors, and lets every object/plant/building “snap” to the correct ground level.                               |
| **nDSM / surface height**        | • `RealisticTerrainRenderInfo` ( `surface_height_layer` )<br>• `VegetationRenderInfo` / `VectorVegetationRenderInfo` (their `height_layer` is typically the canopy-height or nDSM raster)                                                                                                                                                                                      | Provides above-ground relief: Realistic Terrain blends it with the DTM for a true‐to‐life surface, while vegetation renderers convert it to individual tree/plant heights. |
| **Land-use / land-cover raster** | • `RealisticTerrainRenderInfo` ( `landuse_layer` )<br>• `VegetationRenderInfo` ( `landuse_layer` )                                                                                                                                                                                                                                                                             | Guides texture selection (grass, soil, water, etc.) in the terrain shader and determines which vegetation type should grow in each cell.                                   |
| **Point features**               | • `ObjectRenderInfo`, `WindTurbineRenderInfo` ( `geo_feature_layer` )<br>• `RepeatingObjectInfo` ( `geo_feature_layer` )<br>• `VectorVegetationRenderInfo` ( `plant_layer` – often points)<br>• `RoadNetworkRenderInfo` ( `road_intersections` )                                                                                                                               | Each point spawns one scene or multimesh instance (trees, turbines, furniture, etc.). Intersections become junction markers in the road network.                           |
| **Line features**                | • `RoadNetworkRenderInfo` ( `road_roads` )<br>• `ConnectedObjectInfo` (power-line cables, etc.)<br>• `RepeatingObjectInfo` (when fed a line layer, objects are tiled along the polyline)                                                                                                                                                                                       | Rendered as extruded road meshes, hanging cables, or regularly spaced objects along the path.                                                                              |
| **Polygon features**             | • `BuildingRenderInfo` ( `geo_feature_layer` )<br>• `PolygonObjectInfo` ( `polygon_layer` )<br>• `VectorVegetationRenderInfo` (plant polygons, if supplied)                                                                                                                                                                                                                    | Footprints are extruded to 3-D buildings or filled with instanced objects; polygon objects distribute assets on a lattice inside each polygon.                          |

[1]: https://raw.githubusercontent.com/boku-ilen/landscapelab/master/Layers/LayerComposition.gd "raw.githubusercontent.com"


### Planning Game

One key element of the LL is what we usually refer to as the "Table" [see the UI](UI/LabTable/LabTable.tscn). As mentioned, the LL is a tool used in participatory planning workshops. To support discussions in larger groups we created an input-interface that is not bottlenecked by a single person operating traditional input methods (i.e. mouse and keyboard). Leveraging the [landscapelab-table](https://github.com/boku-ilen/landscapelab-table) software, on a 2D map interface (usually projected onto a table), a camera can detect 3 colors and 2 sizes of toy-bricks which define some sort of input. For instance, we could define a setup like:
- blue brick: teleport player position to point
- green brick: set wind-turbine
- red brick: set building

## Setup

Currently, setting up the LandscapeLab is a cumbersome process, that may require internal knowledge. For small project that should be able to load geodata in real-time, we recommend having a look at our more user-friendly GDNative plugin [Geodot](https://github.com/boku-ilen/geodot-plugin) which is also used by the LL. If, however, you really want to set up the LandscapeLab, feel free to contact us at in the [Geodot Discord server](https://discord.gg/MhB5sG7czF), where we frequently communicate with users and collaborators.

We intend to make this tool more accessible (e.g. providing a more sophisticated documentation/wiki), but currently lack time-resources and workforce. Also, we currently don't provide an executable runtime package. 

Superficially, the process of setting up the LandscapeLab requires the following steps:

* Get the [latest Geodot build for your platform](https://github.com/boku-ilen/geodot-plugin/actions) and copy the `addons/geodot` folder into this project
* Prepare sensible geodata
    * Look into section project structure and philosophy for more information
    * Most layer-compositions and renderers are based on a height-model for "placement on the ground" plus some additional data and meta-configurations for what to render (e.g. point-data for and 3D-asset configuration for what to render in the case of the most trivial `Object`-LayerComposition)
* Copy Setup/configuration.ini to configuration.ini in the `user://` path (`AppData` on Windows, `.local/share` on Linux) and adapt the Config path
    * On Linux, you can also use `Setup/setup_linux.sh` for this
* For the config, we use `.ll` files - a custom `.json` format, where different sections may or need to be defined
    * See `Setup/example.ll` for more context
* Open the Godot project 
* Run the main scene

## Contribution

Collaboration is greatly appreciated! As mentioned previously, if you require help for the setup to contribute, feel free to contact us. You can test and report bugs, fix known issues or submit new functionality by opening pull requests.

## Credits

A build of our [Geodot plugin](https://github.com/boku-ilen/geodot-plugin) is included, along with the required GDAL library. All credits for GDAL go to [OSGeo/gdal](https://github.com/OSGeo/gdal/) ([license](https://raw.githubusercontent.com/OSGeo/gdal/master/gdal/LICENSE.TXT)).
