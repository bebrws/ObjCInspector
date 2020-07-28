# ObjCInspector


One of my many scratch projects. In this one I am trying to do what I have done in a frida script where I get all classes from a specific module.

Then hook classes sublasses a speciifc class.

Currently this dylib can be injected into any App and it will create and NSMutableDictionairy with all Obj C classes from all modules.

The TODO: is to add in the hooking of NSResponder based classes on MouseDown so I have a nice dylib I can inject into any app to click around and learn which class is for what NSView.

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
