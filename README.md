# IS'SIM

## Description

A modular web development panel to manage and virtualize environments based on the SpinalCore technology.
Its built-in features include: 
* Structurated data definition and display,
* 3D rendering (WebGL) of pre-defined models,
* Real-time alerts and interaction, 
* Possibility to connect to external softwares and analytics,
* Collaborative work within a SpinalCore architecture,
* Physical devices discovery and communication,
* ...

## Structure

IS'SIM is divided into two parts: a library of SpinalCore models and processes and an browser utility that builds the web development panel from the library.

The utility needs the library, but the library can also be used for any other organ.

<a href='https://github.com/spinalcom/lib_is-sim' target='_blank'>Library repository</a>

<a href='https://github.com/spinalcom/utility_is-sim' target='_blank'>Utility repository</a>


## Installation

To use the IS'SIM library and utility, you have to work with a SpinalCore framework: see the <a href='https://github.com/spinalcom/spinal-framework' target='_blank'>spinal-framework repository</a> for more information.

Install the IS'SIM library in the *js-libraries/* folder:
```
~/path/to/your-spinal-framework/js-libraries/ git clone https://github.com/spinalcom/lib_is-sim.git
```

Install the IS'SIM utility in the *organs/browser/* folder:
```
~/path/to/your-spinal-framework/organs/browser/ git clone https://github.com/spinalcom/utility_is-sim.git
```

## Compilation

### Library

To build the sources of the library:

```
~/path/to/your-spinal-framework/js-libraries/lib_is-sim$ make
```

This will build the main files of the library: **models.js**, **processes.js** and **stylesheets.css**

To clean the generated files:

```
~/path/to/your-spinal-framework/js-libraries/lib_is-sim$ make clean
```

### Utility

To build the sources of the utility:

```
~/path/to/your-spinal-framework/organs/browser/utility_is-sim$ make
```

This will build the main files of the library: **processes.js** and **stylesheets.css**, and also put the html files (**admin.html**, **desk.html** and **lab.html**) in the *browser/* folder.

To clean the generated files:

```
~/path/to/your-spinal-framework/organs/browser/utility_is-sim$ make clean
```


## Configuration

### Library

Nothing to configure here.

### Utility

To configure the IS'SIM utility, modify the **config.js** file in the *utility_is-sim/* folder. Here is the default content:
```
var USER = { userid: '168', password: 'JHGgcz45JKilmzknzelf65ddDftIO98P' };

var MODELS = [];

var APPLIS = [];

var LIBS = [];
```
It contains 4 variables that should always be defined (empty or not):

- **USER**: the ID and the password to connect to the SpinalHub.
- **MODELS**: a list of **strings** of the JavaScript files of the libraries (coming from the *js-libraries* folder) you want to include in the utility. The IS'SIM is already included, so you don't need to put it here.
- **APPLIS**: a list of **strings** of the application classes you want to use in the utility. An application class is a specific model of the IS'SIM library.
- **LIBS**: a list of **strings** of the JavaScript external libraries you want to include in the utility. These libraries have to be put in the *browser/libJS/* folder in your framework.

Here is an example of a filled config.js file:
```
var USER = { userid: '168', password: 'JHGgcz45JKilmzknzelf65ddDftIO98P' };

var MODELS = [ 'custom_my-library-1', 'custom_my-library-2' ];

var APPLIS = [ 'TreeAppApplication_1', 'TreeAppApplication_2', 'TreeAppApplication_3' ];

var LIBS = [ 'math', 'numeric-1.2.6.min' ];
```


## Basic usage

### Library

The IS'SIM library contains models that can be used for any organ you create or download.


### Utility

The IS'SIM utility is running through 3 html pages: **desk.html**, **lab.html** and **admin.html**.

To load these pages, you will need to run the SpinalHub of your spinal-framework first. See the <a href='http://doc.spinalcom.com/' target='_blank'>SpinalCore documentation</a> for more information.

#### Desk
![desk_files](https://cloud.githubusercontent.com/assets/14069348/16004140/571cf824-3160-11e6-8206-1263e00e4a5b.png)
![desk_projects](https://cloud.githubusercontent.com/assets/14069348/16004142/5898e03c-3160-11e6-8a9b-5673669fa4e9.png)

The desk panel allows you to handle files in your SpinalCore database and create projects, which correspond to a independant Lab.


#### Lab
![lab](https://cloud.githubusercontent.com/assets/14069348/16004145/5b2eb254-3160-11e6-9af8-69be8e7b9e65.png)
![lab_ex2](https://cloud.githubusercontent.com/assets/14069348/16035930/e526a110-3219-11e6-8418-33b73f4a0ca1.png)

The lab is the working environment of is-sim. It is composed of different panels/toolbars:
  1. **Main toolbar**: Inclusion of your files and applications, animation panel if you have applications that use time parameters.
  2. **Scene panel**: Representation of the whole architecture of the Lab data. Data in is-sim is represented by tree-items displayed here. The **Session** item is the main model of the Lab.
  3. **3D window**: WebGL environment that can display the drawable models present in the Scene panel. The coordinates system is represented in the bottom-left corner and a toolbar to move the camera, hide elements and splice the window is at the top.
  4. **Inspector panel**: Display of the attributes of the tree-item selected in the Scene panel. Attributes are sub-models of a model that allows to have structurated data.
  5. **Contextual toolbar**: Display of buttons actions associated to the selected tree-item in the Scene panel. These actions are analytics or algorithms that can act on the data (the whole session, not only the selected tree-item).

#### Admin

The Admin interface is similar to the Desk. It allows to manage the FileSystem of your SpinalHub.

It should only be used for an advanced usage. It is a very light version of the <a href='https://github.com/spinalcom/admin-dashboard' target='_blank'>Admin Dashboard utility</a>.


