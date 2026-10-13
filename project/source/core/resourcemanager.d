
//import bindbc.sdl.mixer;
//import sdl_mixer;
import bindbc.sdl;
import std.file;
import std.stdio;
import std.string;

Mix_Chunk*[string] audio;
// font | size
TTF_Font*[int][string] font;
// font | size | text
// SDL_Texture*[string][int][string] text_texture;

SDL_Renderer* renderer;

string[string] script;
string audio_path = "./assets/audio/";
string script_path = "./assets/scripts/";
// string font_path = "./assets/fonts/";


import std.conv;

void loadAudio() {
    foreach(string filename; dirEntries(audio_path, "*.wav", SpanMode.shallow)) {
        string key = filename[audio_path.length .. $-4];
        writeln(key ~ " : mp3 = " ~ filename);
        audio[key] = Mix_LoadWAV(filename.toStringz);
    }
}

void loadScripts() {
    foreach(string filename; dirEntries(script_path, "*.py", SpanMode.shallow)) {
        string key = filename[script_path.length .. $-3];
        writeln(key ~ " : script = " ~ filename);

        script[key] = readText(filename);
    }
}

void PlayAudio(string name) {
    Mix_PlayChannel(-1, audio[name], 0);
}

// void loadFont(string name, int size) {
// 	if (!(name in font)) {
// 		TTF_Font*[int] temp;
// 		font[name] = temp;
// 	}
// 	if (!(size in font[name])) font[name][size] = TTF_OpenFont((font_path ~ name ~ ".ttf").toStringz, size);
// }

// void CreateRenderer(SDL_Window* window) {
// 	renderer = SDL_CreateRenderer(window, null);
// }

// SDL_Surface* CreateText(string text, string font_name, int size, SDL_Color color, SDL_FRect* location) {
// 	if (font_name in text_texture && size in text_texture[font_name] && text in text_texture[font_name][size]) {
// 		//return text_texture[font_name][size][text];
// 	}
// 	loadFont(font_name, size);
// 	TTF_Font *font = font[font_name][size];
// 	SDL_Surface* surface = TTF_RenderText_Blended(font, text.toStringz, text.length, color);
// 	// SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
// 	location.w = surface.w;
// 	location.h = surface.h;
// 	return surface;
// 	// SDL_DestroySurface(surface);
// 	// if (!(font_name in text_texture)) {
// 	// 	SDL_Texture*[string][int] temp;
// 	// 	text_texture[font_name] = temp;
// 	// }
// 	// if (!(size in text_texture[font_name])) {
// 	// 	SDL_Texture*[string] temp;
// 	// 	text_texture[font_name][size] = temp;
// 	// }
// 	// text_texture[font_name][size][text] = texture;
// 	// return texture;
// }

// bool RenderText(SDL_Texture* texture, SDL_FRect* location) {
// 	return SDL_RenderTexture(renderer, texture, null, location);
// }

