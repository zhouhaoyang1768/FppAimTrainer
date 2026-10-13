// Load the SDL2 library
module sdl_abstraction2;

import std.stdio;
import std.string;

import bindbc.sdl;
import bindbc.freetype;
import bindbc.loader;
//import bindbc.sdl.ttf; 
import sdl_ttf;
import loader = bindbc.loader.sharedlib;
// global variable for sdl;
const LoadMsg ret;
const LoadMsg ttf_ret;
const LoadMsg mixer_ret;
/// At the module level we perform any initialization before our program
/// executes. Effectively, what I want to do here is make sure that the SDL
/// library successfully initializes.
shared static this(){
		// Load the SDL libraries from bindbc-sdl
		// on the appropriate operating system
    version(Windows){
    		writeln("Searching for SDL on Windows");
				ret = loadSDL("SDL3.dll");
		}
  	version(OSX){
      	writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){ 
      	writeln("Searching for SDL on Linux");
				ret = loadSDL();
		}

		// Error if SDL cannot be loaded
    if(ret != LoadMsg.success){
        writeln("error loading SDL library");    
        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == LoadMsg.noLibrary){
        writeln("error no library found");
    }
    if(ret == LoadMsg.badLibrary){
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }

    version(Windows){
    		writeln("Searching for SDL TTF on Windows");
            ttf_ret = loadSDLTTF("SDL3_ttf.dll");
		}
  	version(OSX){
      	writeln("Searching for SDL TTF on Mac");
        ttf_ret = loadSDLTTF();
    }
    version(linux){ 
      	writeln("Searching for SDL TTF on Linux");
				ttf_ret = loadSDLTTF();
	}

    if(ttf_ret != LoadMsg.success) {
        writeln("Error loading true type font");
    }

    version(Windows){
        writeln("Searching for SDL Mixer on Windows");
        mixer_ret = loadSDLMixer("SDL3_mixer.dll");
    }
  	version(OSX){
      	writeln("Searching for SDL Mixer on Mac");
        mixer_ret = loadSDLMixer();
    }
    version(linux){ 
      	writeln("Searching for SDL Mixer on Linux");
		mixer_ret = loadSDLMixer();
	}

    if(mixer_ret != LoadMsg.success) {
        writeln("Error loading audio");
    }

    if (Mix_Init(MIX_INIT_MP3) == 0) {
        writeln("TTF_Init: ", fromStringz(SDL_GetError()));
    }

    if(TTF_Init() == 0) {
        writeln("TTF_Init: ", fromStringz(SDL_GetError()));
    }
    // Initialize SDL
    if(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_JOYSTICK| SDL_INIT_HAPTIC | SDL_INIT_GAMEPAD | SDL_INIT_EVENTS | SDL_INIT_SENSOR | SDL_INIT_CAMERA) == 0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }
    SDL_AudioSpec spec;
    spec.freq = MIX_DEFAULT_FREQUENCY;
    spec.format = MIX_DEFAULT_FORMAT;
    spec.channels = MIX_DEFAULT_CHANNELS;
    if( !Mix_OpenAudio( 0, &spec)) {
        writeln( "SDL_mixer could not initialize! SDL_mixer Error: ", fromStringz(SDL_GetError()) );
    }

    loadFT();
    
}

bool loadFT(){
	FTSupport ret;

    version(Windows){
        writeln("Searching for FT on Windows");
        ret = loadFreeType("freetype.dll");
    }
  	version(OSX){
      	writeln("Searching for FT on Mac");
        ret = loadFreeType();
    }
    version(linux){ 
      	writeln("Searching for FT on Linux");
		ret = loadFreeType();
	}

    
	if(ret != ftSupport){
		//Log the error info
		foreach(info; loader.errors){
			/*
			A hypothetical logging function. Note that `info.error` and
			`info.message` are `const(char)*`, not `string`.
			*/
            writeln(info.message);
			//logError(info.error, info.message);
		}
		
		//Optionally construct a user-friendly error message for the user
		string msg;
		if(ret == FTSupport.noLibrary){
			msg = "This application requires the FreeType library.";
		}
		//A hypothetical message box function
		//showMessageBox(msg);
        writeln(msg);
		return false;
	}


	return true;
}

/// At the module level, when we terminate, we make sure to 
/// terminate SDL, which is initialized at the start of the application.
shared static ~this(){
    // Quit the SDL Application 
    SDL_Quit();
		writeln("Ending application--good bye!");
}
