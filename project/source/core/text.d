import bindbc.freetype;
import bindbc.opengl;
import bindbc.sdl;

import std.stdio;

string font_path = "./assets/fonts/";

FT_Library ft;
FT_Face face;

struct Character {
    uint   TextureID;
    int[2] Size;
    int[2] Bearing;
    uint   Advance;
}

Character[char] Characters;
uint VAO, VBO;

int font_size;

bool loadFont(int size = 20) {
	font_size = size;
    if (FT_Init_FreeType(&ft))
    {
        writeln("ERROR::FREETYPE: Could not init FreeType Library");
        return false;
    }

	if (FT_New_Face(ft, (font_path ~ "genshin.ttf").ptr, 0, &face))
	{
		writeln("ERROR::FREETYPE: Failed to load font");  
		return false;
	}


	FT_Set_Pixel_Sizes(face, 0, size);  
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1); // disable byte-alignment restriction
  
    for (ubyte c = 0; c < 128; c++)
    {
        // load character glyph 
        if (FT_Load_Char(face, c, FT_LOAD_RENDER))
        {
            writeln("ERROR::FREETYTPE: Failed to load Glyph");
            continue;
        }
        // generate texture
        GLuint texture;
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RED,
            face.glyph.bitmap.width,
            face.glyph.bitmap.rows,
            0,
            GL_RED,
            GL_UNSIGNED_BYTE,
            face.glyph.bitmap.buffer
        );

        // set texture options
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // now store character for later use
        Character character = {
            texture, 
            [face.glyph.bitmap.width, face.glyph.bitmap.rows],
            [face.glyph.bitmap_left, face.glyph.bitmap_top],
            face.glyph.advance.x
        };
        Characters[c] = character;
    }

    FT_Done_Face(face);
    FT_Done_FreeType(ft);

    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, float.sizeof * 6 * 4, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*)0);
    glEnableVertexAttribArray(0); 

    
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*)(2*float.sizeof));
    glEnableVertexAttribArray(1);  
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);  
    return true;
}


float wh_ratio;

void SetWidthHeightRatio(float ratio) {
    wh_ratio = ratio;
}

float[4][6] vertices;
void RenderText(uint prog, string text, float x, float y, float scale, SDL_Color color)
{
    // activate corresponding render state	
    glUseProgram(prog);

    // GLuint loc = glGetUniformLocation(prog, "text");
    // glUniform1i(loc, 0);

    glUniform3f(glGetUniformLocation(prog, "textColor"), color.r / 256.0, color.g / 256.0, color.b / 256.0);
    glActiveTexture(GL_TEXTURE0);
    glBindVertexArray(VAO);


    // iterate through all characters

    scale /= 500 * font_size;
    float scaleX = scale / wh_ratio;
    float scaleY = scale;
    foreach (char c; text)
    {
        Character ch = Characters[c];

        float xpos = x + ch.Bearing[0] * scaleX;
        float ypos = y - (ch.Size[1] - ch.Bearing[1]) * scaleY;

        float w = ch.Size[0] * scaleX;
        float h = ch.Size[1] * scaleY;
        // update VBO for each character
        vertices = [
            [ xpos,     ypos + h,   0.0f, 0.0f ],            
            [ xpos,     ypos,       0.0f, 1.0f ],
            [ xpos + w, ypos,       1.0f, 1.0f ],

            [ xpos,     ypos + h,   0.0f, 0.0f ],
            [ xpos + w, ypos,       1.0f, 1.0f ],
            [ xpos + w, ypos + h,   1.0f, 0.0f ]           
        ];
        // render glyph texture over quad
        glBindTexture(GL_TEXTURE_2D, ch.TextureID);
        // update content of VBO memory
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferSubData(GL_ARRAY_BUFFER, 0, (vertices).sizeof, vertices.ptr); 
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glDrawArrays(GL_TRIANGLES, 0, 6);
        // now advance cursors for next glyph (note that advance is number of 1/64 pixels)
        x += (ch.Advance >> 6) * scaleX; // bitshift by 6 to get value in pixels (2^6 = 64)
    }
    glBindVertexArray(0);
    glBindTexture(GL_TEXTURE_2D, 0);
}