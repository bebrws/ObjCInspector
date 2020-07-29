# ObjCInspector


It hooks al NSResponder parent classes ignore NSViewControllers and logs out the classname followed by a methods list and ivars list

To use:

checkout 

https://github.com/bebrws/injector

Then:

        # run an app from the terminal
        /Applicatoins/Some.app/Contents/MacOS/SomeApp # in terminal 1
        sudo injector PIDOFAPP /libObjCInspector.dylib  # in terminal 2
    
Or:
    
    DYLD_INSERT_LIBRARIES=libObjCInspector.dylib /Applicatoins/Some.app/Contents/MacOS/SomeApp
    
Then click around and watch the terminal.


This should all be easily portable to iOS too which I guess will be a todo.

I will post the frida script to:

https://github.com/bebrws/bebrws-frida-scripts

as welll.


This ended up getting me all the objc classes at the ned of hte day..

        unsigned int imageCount=0;
        const char **imageNames=objc_copyImageNames(&imageCount);
        for (int i=0; i<imageCount; i++){
            const char *imageName=imageNames[i];
            const char **names = objc_copyClassNamesForImage((const char *)imageName,&count);
            for (int i=0; i<count; i++){
                const char *clsname=names[i];
                
                printf("%s - %s\n", imageName, clsname);
            }
        }




This should be useful for figuring out how to hook and theme/mod a program or add new functionality to an older app.


