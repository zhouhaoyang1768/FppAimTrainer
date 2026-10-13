/// OBJ File Creation
module objgeometry;

import bindbc.opengl;
import std.stdio;
import geometry;
import stream;
import error;
import vec;

struct vertex {
    int vertex_index;
    int texture_index;
    int norm_index;
}

vertex decode(string s) {
    import std.array;
    import std.conv;
    vertex result;
    string[] v = s.split('/');
    
    result.vertex_index = v[0] == "" ? -1 : to!int(v[0]) - 1;
    result.texture_index = v[1] == "" ? -1 : to!int(v[1]) - 1;
    result.norm_index = v[2] == "" ? -1 : to!int(v[2]) - 1;
    return result;
}

/// Geometry stores all of the vertices and/or indices for a 3D object.
/// Geometry also has the responsibility of setting up the 'attributes'
class SurfaceOBJ : ISurface{
    GLuint mVBO;
    GLuint mIBO;
    GLfloat[] mVertexData;
	GLfloat[] mNormalData;
	GLfloat[] mTextureData;
    GLuint[] mIndexData;
    size_t mTriangles;

    /// Geometry data
    this(string filename){
        MakeOBJ(filename);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawElements(GL_TRIANGLES,cast(GLuint)mIndexData.length,GL_UNSIGNED_INT,null);
    }



    void MakeOBJ(string filepath){
        import std.file;
        //Mesh m;

        string content = readText(filepath);
        Stream ss = new Stream(content);

        vec3[] v = [];
        vec3[] vn = [];
        //GLfloat[] vertex_data = [];
        //GLint[] index_data = [];
        int[vertex] index;

        int next_index = 0;

        while(!ss.eof()) {
            Stream line = new Stream(ss.nextLine());
            string prefix = line.next();
            if (prefix == "v") {
                v ~= vec3(line.nextFloat(), line.nextFloat(), line.nextFloat());
            } else if (prefix == "vn") {
                vn ~= vec3(line.nextFloat(), line.nextFloat(), line.nextFloat());
            } else if (prefix == "f") {
                vertex v1 = line.next().decode();
                vertex v2 = line.next().decode();
                vertex v3 = line.next().decode();

                void append_vertex(vertex _v) {
                    index[_v] = next_index;
                    mVertexData ~= v[_v.vertex_index].x;
                    mVertexData ~= v[_v.vertex_index].y;
                    mVertexData ~= v[_v.vertex_index].z;
                    // vt
                    mNormalData ~= vn[_v.norm_index].x;
                    mNormalData ~= vn[_v.norm_index].y;
                    mNormalData ~= vn[_v.norm_index].z;
                    
                    next_index++;
                }

                if (! (v1 in index)) append_vertex(v1);
                if (! (v2 in index)) append_vertex(v2);
                if (! (v3 in index)) append_vertex(v3);

                mIndexData ~= index[v1];
                mIndexData ~= index[v2];
                mIndexData ~= index[v3];
            }
        }

        //for (int i = 0; i < vertex_data.length; ++i) {
    //       if (i % 6 == 0) writeln(vertex_data[i], ' ', vertex_data[i + 1], ' ', vertex_data[i + 2], '\n', vertex_data[i + 3], ' ',  vertex_data[i + 4], ' ', vertex_data[i + 5], '\n');
    //  }

        //writeln(ss.text.length);

        //writeln(m.mTriangles);
        mTriangles = mIndexData.length;
		// TODO 
		// You can erase all of this code, or otherwise add the parsing of your OBJ
		// file here.

		
        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) 
        // that we want to work withn.
        glBindVertexArray(mVAO);

        // Index Buffer Object (IBO)
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndexData.length* GLuint.sizeof, mIndexData.ptr, GL_STATIC_DRAW);

        // Vertex Buffer Object (VBO) creation
        GLfloat[] allData;
        for(size_t i=0; i < mVertexData.length; i+=3){
            allData ~= mVertexData[i];
            allData ~= mVertexData[i+1];
            allData ~= mVertexData[i+2];
            allData ~= mNormalData[i];
            allData ~= mNormalData[i+1];
            allData ~= mNormalData[i+2];
        }

        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, allData.length* VertexFormat3F3F.sizeof, allData.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);
        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F3F();
    }
}

