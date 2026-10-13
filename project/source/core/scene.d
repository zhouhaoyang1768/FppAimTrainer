module scene;

import text;
import linear;
import camera;
import scene;
import pipeline;
import resourcemanager;

import std.range;
import std.stdio;

import bindbc.sdl;
import bindbc.opengl;

/// A Scene Tree is a data structure that stores all of the 'ISceneNode' types. 
/// It is traversed 
class SceneTree{
    ISceneNode mRootNode;
    // Camera
    Camera mCamera = null;

    /// Default constructor for creating a new Scene Tree
    this(string rootName){
        // Create the initial root node.
        // By default this is a 'GroupNode' which 
        // does not have anything other than
        // a name associated with it.
        mRootNode = new GroupNode(rootName);
    }

    /// Retrieve the root node
    ISceneNode GetRootNode(){
        return mRootNode;
    }

    /// Set the root node to another node.
    /// Useful if you want to only traverse a part of the sub-tree.
    void SetRootNode(ISceneNode newRootNode){
        mRootNode = newRootNode;
    }

    /// Set the camera that we will use for the scene tree traversal
    /// We also 'cache' the 'view' and 'projection' matrix
    void SetCamera(Camera camera){
        mCamera = camera;
    }

    /// Performs a traversal and returns the node if it exists
    ISceneNode FindNode(string name){
        if(name.length==0){
            assert(0,"Failure, cannot query for a node name of length 0");
        }
        // Test if root node is our query, otherwise we'll
        // proceed to perform DFS
        if(name == GetRootNode.mNodeName){
            return GetRootNode();
        }

        // Perform a depth-first traversal
        ISceneNode current = mRootNode;
        ISceneNode[] stack = current.mChildren;

        while(stack.length > 0){
            /// End of array (top of stack) is now current node.
            current = stack[$-1];
            if(current.mNodeName == name){
                return current;
            }
            // Remove the current node from stack
            stack.popBack();
            // Append all of the children to the back of the stack
            stack ~= current.mChildren;
        }

        writeln("Node '"~name~"' could not be found! in 'FindNode'.");
        return null;
    }

    /// Start the traversal of the scene tree
    void StartTraversal(){
        if(mCamera is null){
            assert(0,"Error: No camera attached to Scene tree for traversal, use SetCamera()");
        }

        
        foreach(child ; mRootNode.mChildren){
            child.Update();
        }


        /* TODO for students
        // Perform a depth-first traversal
        ISceneNode current = mRootNode;
        current.Update();
        ISceneNode[] stack = current.mChildren;

        while(stack.length > 0){
            /// End of array (top of stack) is now current node.
            current = stack[$-1];
            // Remove the current node from stack
            stack.popBack();
            // Perform update on current node
            current.Update();
            // Append all of the children to the back of the stack
            stack ~= current.mChildren;
        }
        */
    }

}

/// Everything in this abstraction is a 'node'
/// Every node has:
/// - A parent
/// - 0 or more children
/// - A friendly 'string name' representation of the node.
/// - A 'modelMatrix' for transformations
abstract class ISceneNode{
    ISceneNode   mParent = null;
    ISceneNode[] mChildren;
    mat4 mModelMatrix;	        // Transformation of our node
    string       mNodeName;     // Node Name -- useful for debugging

    /// Returns the parent scene node.
    /// If mParent is null, then this is either the 'root' node, or
    /// an invalid node
    ISceneNode GetParentSceneNode(){
        return mParent;
    }

    /// Adds a child node to the current Scene Node
    void AddChildSceneNode(ISceneNode node){
        node.mParent = this;
        this.mChildren ~= node;
    }

    /// Every node needs to implement an 'Update' function
    void Update();
}

/// A node for simply grouping entities together
class GroupNode : ISceneNode{
    this(){
    }
    /// Constructor for a Group Node to have a name
    this(string name){
        mNodeName = name;
    }

    override void Update(){
    }
}

import mesh;
import std.random;
import pyd.pyd;
import pyd.embedded;
import std.conv;
import std.datetime;

//import core.sys.mmeapi;

abstract class Scene {
    Camera camera = null;

    void SetCamera(Camera c) {
        camera = c;
    }
    void Input();
    void Update();
    void Render(Camera cam);
}

class GameScene : Scene {
    public:
    MeshNode targetMesh;
    MeshNode wallMesh;
    MeshNode lightMesh;
    MeshNode hpBarMesh;

    const static int n = 6;

    vec3[n] targets;
    InterpContext[n] context;
    float[n] radius;
    bool tracking;
    int[n] max_hp;
    int[n] current_hp;

    int window_w;
    int window_h;

    float wh_ratio;

    int fps_counter;
    int fps_to_render;
    float hits_per_second;
    float score_per_minute;

    int hits_first_minute;
    float score_first_minute;

    SysTime begin_time;    
    SysTime last_time;
    SysTime last_update;
    SysTime now;

    void reset_stats() {
        // waveOutSetVolume(null, 0);

        fps_counter = 0;
        fps_to_render = 0;
        hits_per_second = 0;
        score_per_minute = 0;
        hits_first_minute = 0;
        score_first_minute = 0;

        last_time = Clock.currTime();
        begin_time = last_time;
        last_update = last_time;
        num_hits = 0;
        num_shots = 0;
    }

    this(MeshNode target, MeshNode wall, MeshNode light, MeshNode hpBar, int w, int h) {
        window_w = w;
        window_h = h;

        tracking = false;
        
        wh_ratio = (cast(float)w) / h;



        this.targetMesh = target;
        this.wallMesh = wall;
        this.lightMesh = light;
        this.hpBarMesh = hpBar;

        loadAudio();
        loadScripts();

        for (int i = 0; i < n; ++i) {
            context[i] = new InterpContext();

            new_target(i);
        }
        create_crosshair_mesh();
        create_square_mesh();
        SDL_HideCursor();

        SetWidthHeightRatio(wh_ratio);
        reset_stats();
    }


    uint VBO_crosshair;
    uint VAO_crosshair;

    void create_crosshair_mesh() {
        float s = 0.003;
        float l = s * 2.6;


        GLfloat[] vertices = [
            0, 0,
            s, s,
            l, s,
            l, -s,
            s, -s,
            s, -l,
            -s, -l,
            -s, -s,
            -l, -s,
            -l, s,
            -s, s,
            -s, l,
            s, l,
            s, s,
        ];

        for (int i = 0; i < vertices.length; i += 2) {
            vertices[i] /= wh_ratio;
        }


        glGenVertexArrays(1, &VAO_crosshair);
        glBindVertexArray(VAO_crosshair);

        glGenBuffers(1, &VBO_crosshair);
        glBindBuffer(GL_ARRAY_BUFFER, VBO_crosshair);
        glBufferData(GL_ARRAY_BUFFER, vertices.sizeof * vertices.length, cast(void*)vertices, GL_STATIC_DRAW);

        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * float.sizeof, cast(void*)0);
        glEnableVertexAttribArray(0);  

        glBindVertexArray(0);
        glDisableVertexAttribArray(0);
    }

    uint VBO_square;
    uint VAO_square;

    void create_square_mesh() {
        float w = 0.1, h = 0.1;

        GLfloat[] vertices = [
            -w, -h, 0, 0,
            w, -h, 1, 0,
            w, h, 1, 1,
            -w, -h, 0, 0,
            w, h, 1, 1,
            -w, h, 0, 1
        ];

        for (int i = 0; i < vertices.length; i += 4) {
            vertices[i] /= wh_ratio;
        }


        glGenVertexArrays(1, &VAO_square);
        glBindVertexArray(VAO_square);

        glGenBuffers(1, &VBO_square);
        glBindBuffer(GL_ARRAY_BUFFER, VBO_square);
        glBufferData(GL_ARRAY_BUFFER, vertices.sizeof * vertices.length, cast(void*)vertices, GL_STATIC_DRAW);

        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*)0);
        glEnableVertexAttribArray(0); 

        
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * float.sizeof, cast(void*)(2*float.sizeof));
        glEnableVertexAttribArray(1);  

        glBindVertexArray(0);
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
    }

    auto rnd = Random(1000);
    void new_target(int i) {
        context[i].r = 0.1;
        context[i].hp = 1;
        if ("init_target" in script) {
            context[i].py_stmts(script["init_target"]);
        }
        radius[i] = context[i].py_eval!float("r");
        max_hp[i] = context[i].py_eval!int("hp");
        current_hp[i] = max_hp[i];
        if (max_hp[i] > 1) tracking = true;

        float x = uniform!"[]"(0, 1.0f, rnd) * 2 - 1;
        float y = uniform!"[]"(0, 1.0f, rnd) * 2 - 1;
        vec3 new_loc = vec3(x * 2, y * 2, -box_width / 2 + radius[i] * 4);
        for (int j = 0; j < n; ++j) {
            if (Distance(new_loc, targets[j]) <= (radius[i] + radius[j]) * 2) {
                new_target(i);
                return;
            }
        }

        
        targets[i] = new_loc;
        current_hp[i] = max_hp[i];
    }

    float box_width = 6.0f;
    void render_box(int dx, int dy, int dz) {
        wallMesh.mModelMatrix = MatrixMakeTranslation(vec3(dx * box_width * 1, dy * box_width * 1, dz * box_width * 1)) * MatrixMakeScale(vec3(box_width/2, box_width/2, box_width/2));
        wallMesh.Update();
    }

    void render_hp(int i) {
        if (!tracking || current_hp[i] == max_hp[i]) 
            return;
        

        static vec3 frameColor = vec3(0, 0, 0);
        static vec3 hpColor = vec3(0, 1, 0);

        float w = 0.025;
        float hp_percent = (cast(float)current_hp[i]) / max_hp[i];




        
        hpBarMesh.mModelMatrix = MatrixMakeTranslation(targets[i] + vec3(0, -radius[i] - w, 0))* MatrixMakeScale(vec3(radius[i] + w*0.4, w*1.4, w/6.0));
        hpBarMesh.mMaterial.mUniformMap["vColor"].Set(frameColor.DataPtr);
        hpBarMesh.Update();

        hpBarMesh.mModelMatrix = MatrixMakeTranslation(targets[i] + vec3(-radius[i] * (1 - hp_percent), -radius[i] - w, 0))* MatrixMakeScale(vec3(radius[i] * hp_percent, w, w/4.0));
        hpBarMesh.mMaterial.mUniformMap["vColor"].Set(hpColor.DataPtr);
        hpBarMesh.Update();
    }

    void render_box() {
        render_box(-1, 0, 0);
        render_box(1, 0, 0);
        render_box(0, -1, 0);
        render_box(0, 1, 0);
        render_box(0, 0, -1);
        render_box(0, 0, 1);
    }


    void render_crosshair() {
        
        glDepthFunc(GL_ALWAYS);
        glUseProgram(Pipeline.sPipeline["2d"]);
        glBindVertexArray(VAO_crosshair);

        GLuint loc = glGetUniformLocation(Pipeline.sPipeline["2d"], "color");
		glUniform3f(loc, 1, 1, 1);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 14);

        loc = glGetUniformLocation(Pipeline.sPipeline["2d"], "color");
		glUniform3f(loc, 0, 0, 0);
        glDrawArrays(GL_LINE_LOOP, 1, 12);

        glBindVertexArray(0);
        glDepthFunc(GL_LESS);
    }


    void render_stats() {

        SDL_Color text_color = SDL_Color(0, 0, 0);

        RenderText(Pipeline.sPipeline["2d_texture"], "FPS: " ~ fps_to_render.to!string, 0.7, 0.8, 20, text_color);

        if (!show_stats) return;
        RenderText(Pipeline.sPipeline["2d_texture"], "Accuracy: " ~
                                                      num_hits.to!string ~ "/" ~ num_shots.to!string ~ 
                                                     " (" ~ (num_hits / cast(float)num_shots * 100.0).to!string ~ ("%)")
                                                        , -0.9, 0.8, 12, text_color);

                                                        
        RenderText(Pipeline.sPipeline["2d_texture"], "Hits per second: " ~ hits_per_second.to!string, -0.9, 0.76, 12, text_color);
        RenderText(Pipeline.sPipeline["2d_texture"], "SPM: " ~ score_per_minute.to!string, -0.9, 0.72, 12, text_color);
        
        auto session_time = (now - begin_time).split;
        string time_str = session_time.minutes.to!string ~ ":" ~ session_time.seconds.to!string; 
        RenderText(Pipeline.sPipeline["2d_texture"], time_str, -0.06, 0.8, 50, text_color);
        RenderText(Pipeline.sPipeline["2d_texture"], score_first_minute.to!string, -0.06, 0.7, 30, text_color);
    }
    
    int num_shots = 0;
    int num_hits = 0;
    bool last_mouseLeft = false;

    bool last_key_R = false;
    bool last_key_TAB = false;
    bool show_stats = true;
    override void Input() {
        bool within_first_min = Clock.currTime - begin_time <= 60.seconds;
        const bool* keys = SDL_GetKeyboardState(null);

        float mouseX, mouseY;
        auto mask = SDL_GetMouseState(&mouseX,&mouseY);
        bool clicking = SDL_BUTTON_LEFT & mask;
        if (keys[SDL_SCANCODE_E]) clicking = true;
        if (clicking && (!last_mouseLeft || tracking)) {
            ++num_shots;

            // vec3 n = camera.mForwardVector;
            // vec3 l0 = camera.mEyePosition;
            // vec3 l = -n;
            // ax + by + cz = d

            for (int i = 0; i < targets.length; ++i) {
                vec3 p0 = targets[i];
                // float d = Dot((p0 - l0), n) / Dot(l, n);
                
                // vec3 p = l0 + l * d;
                // float dist = Distance(p, p0);
                float dist = Magnitude(Cross(p0 - camera.mEyePosition, -camera.mForwardVector)) / Magnitude(-camera.mForwardVector);
                //writeln(dist);
                if (dist <= radius[i]) {
                    --current_hp[i];
                    ++num_hits;
                    if (within_first_min) {
                        ++ hits_first_minute;
                    }
                    if (current_hp[i] % 20 == 0)
                        PlayAudio("Blop");
                    if (current_hp[i] == 0) {
                        new_target(i);
                    }
                    break;
                }
            }
            if (within_first_min) {
                score_first_minute = hits_first_minute * 10.0 * cast(float)num_hits / num_shots;
            }
            // writeln(num_hits, "/", num_shots);
        }

        last_mouseLeft = clicking;

        //////////////// Keyboard ////////////////

        // int code_R = SDL_SCANCODE_TAB ;//'r' - 'a' + 4;
        if (!last_key_TAB && keys[SDL_SCANCODE_TAB]) {
            show_stats = !show_stats;
        }
        last_key_TAB = keys[SDL_SCANCODE_TAB];

        if (!last_key_R && keys[SDL_SCANCODE_R]) {
            reset_stats();
        }
        last_key_R = keys[SDL_SCANCODE_R];
    }

    override void Update() {
        static auto one_sec = 1000.msecs;
        static auto _10ms = 5.msecs;

        ++fps_counter;
        now = Clock.currTime;
        if (now - last_time > one_sec) {
            last_time += one_sec;
            fps_to_render = fps_counter;
            fps_counter = 0;
            // writeln("FPS: ", fps_to_render);
            // writeln("Hits per Second: ", num_hits / cast(float)((now - begin_time).total!"msecs") * 1000);
            hits_per_second = num_hits / cast(float)((now - begin_time).total!"msecs") * 1000;
            score_per_minute = hits_per_second * 60 * 10.0 * num_hits / num_shots;
        }

        
        while (now - last_update > _10ms) {
            Input();
            last_update += _10ms;
            if ("update_target" in script) {
                for (int i = 0; i < n; ++i) {
                    context[i].x = targets[i].x;
                    context[i].y = targets[i].y;
                    context[i].z = targets[i].z;
                    context[i].w = box_width;
                    context[i].py_stmts(script["update_target"]);
                    targets[i].x = context[i].py_eval!float("x");
                    targets[i].y = context[i].py_eval!float("y");
                    targets[i].z = context[i].py_eval!float("z");
                }
            }
        }
    }
    override void Render(Camera cam) {
        render_box();
        uint intensity_loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mSpecularIntensity");
        glUniform1f(intensity_loc, 1);
        for (int i = 0; i < n; ++i) {
            vec3 loc = targets[i];
            float scale = radius[i]/2.32;
            targetMesh.mModelMatrix = MatrixMakeTranslation(loc) * MatrixMakeScale(vec3(scale, scale, scale));
            targetMesh.Update();

            render_hp(i);
        }
        render_crosshair();
        render_stats();
    }

}