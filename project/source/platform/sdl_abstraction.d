// /// Load the SDL3 library
// module sdl_abstraction;

// import std.stdio;
// import std.string;

// import bindbc.sdl;
// import bindbc.loader;
// import loader = bindbc.loader.sharedlib;

// // global variable for sdl;
// const LoadMsg ret;

// /// At the module level we perform any initialization before our program
// /// executes. Effectively, what I want to do here is make sure that the SDL
// /// library successfully initializes.
// shared static this(){
// 		import std.array;
// 		writeln("-".replicate(45));
// 		writeln("SDL Setup   ".replicate(3));
// 		writeln("-".replicate(45));

// 		// Load the SDL libraries from bindbc-sdl
// 		// on the appropriate operating system
// 		version(Windows){
// 				writeln("Searching for SDL on Windows");
// 				// NOTE: Windows folks I've defaulted into SDL3, but
// 				// 			 will fallback to try to find SDL2 otherwise.
// 				ret = loadSDL("SDL3.dll");
// 				if(ret != LoadMsg.success){
// 						writeln("Falling back on Windows to find SDL2.dll");
// 						ret = loadSDL("SDL2.dll");
// 				}
// 		}
// 		version(OSX){
// 				writeln("Searching for SDL on Mac");
// 				ret = loadSDL();
// 		}
// 		version(linux){ 
// 				writeln("Searching for SDL on Linux");
// 				ret = loadSDL();
// 		}

// 		// Error if SDL cannot be loaded
// 		if(ret != LoadMsg.success){
// 				writeln("error loading SDL library");    
// 				foreach( info; loader.errors){
// 						writeln(info.error,':', info.message);
// 				}
// 		}
// 		if(ret == LoadMsg.noLibrary){
// 				writeln("error no library found");    
// 		}
// 		if(ret == LoadMsg.badLibrary){
// 				writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
// 		}

// 		if(ret == LoadMsg.success){
// 				/*import std.conv;
// 				SDL_version sdlversion;
// 				SDL_GetVersion(&sdlversion);
// 				writeln(sdlversion);
// 				string msg = "Your SDL version loaded was: "~
// 						to!string(sdlversion.major)~"."~
// 						to!string(sdlversion.minor)~"."~
// 						to!string(sdlversion.patch);
// 				writeln(msg);
// 				if(sdlversion.major==2){
// 						writeln("\nNote:   If SDL2 was loaded, it *may*\n\tbe compatible with SDL3 function calls, \n\tbut some functions different.");
// 				}
// 				*/
// 		}
// 		// Initialize SDL
// 		if(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_JOYSTICK| SDL_INIT_HAPTIC | SDL_INIT_GAMEPAD | SDL_INIT_EVENTS | SDL_INIT_SENSOR | SDL_INIT_CAMERA) !=0){
// 				writeln("SDL_Init: ", fromStringz(SDL_GetError()));
// 		}

// 		writeln("-".replicate(40));
// }

// /// At the module level, when we terminate, we make sure to 
// /// terminate SDL, which is initialized at the start of the application.
// shared static ~this(){
// 		// Quit the SDL Application 
// 		SDL_Quit();
// 		writeln("Shutting Down SDL");
// }
