Copyright 2012 The MathWorks, Inc

== R2012a and R2012b Installation instructions ==

This readme contains instructions on how to install the MATLAB instrument driver for Ocean Optics OmniDiver support.

(1) Create a new directory of your choosing, and unzip the ZIP file into that directory. For example, select all the files, unzip all the files into this directory:

    C:\MATLAB\R2012b\FileExchangeDownloads\


(2) Please install OmniDriver from Ocean Optics. Typically the drivers will be installed in: 
  
    C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME 


(3) Configure MATLAB to use the Ocean Optics driver in R2012b: 

	> The OmniDriver provided by Ocean Optics has a java API
	> To use this API in a MATLAB session you must add two files to the preference directory: 
		javaclasspath.txt 
		javalibrarypath.txt 
	> The content of these files are the installation folder of the OmniDriver described in step (2). Sample files have been provided as part of the package.
	> Open MATLAB and execute the following command. 
		>> prefdir
	
	> The prefdir command will print out the preference directory used by MATLAB. Please copy javaclasspath.txt and javalibrarypath.txt from C:\MATLAB\R2012b\FileExchangeDownloads\ to the preference directory.
	
 
    Note: The contents of the javalibrarypath.txt and javaclasspath.txt are basically the OmniDriver installation folder location. If you have changed the location of the driver installation folder please edit the content of these files appropriately.


(4) Configure MATLAB to use the Ocean Optics driver in R2012a or earlier version: 

	> To use this API in a MATLAB session you must add two files:
		classpath.txt 
		librarypath.txt 
	> The content of these files are the installation folder of the OmniDriver described in step (2). Sample files have been provided as part of the package.
	> Open MATLAB and execute the following commands. 
		>> edit classpath.txt 
		>> edit librarypath.txt

	> The above commands should have opened the classpath.txt and librarypath.txt in the MATLAB editor.
	> Add the OmniDriver installation folder to librarypath.txt. Typically you would have to add
	C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME 
	> Add the OmniDriver java API location to classpath.txt. Typically you would have to add
	C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME\OmniDriver.jar
	
 
    Note: If you have changed the location of the driver installation folder please edit the content of these files appropriately.


(5) Restart MATLAB.
