/// The main graphics application with the main graphics loop.
module graphics_app;
import std.stdio;
import core;
import mesh, linear, scene, materials, geometry;
import resourcemanager;
import platform;

import text;

import bindbc.sdl;
import bindbc.opengl;

/// The main graphics application.
struct GraphicsApp{
		int windowWidth = 1000;
		int windowHeight = 1000;

		bool mGameIsRunning=true;
		bool mRenderWireframe = false;
		SDL_GLContext mContext;
		SDL_Window* mWindow;

		// Scene
		SceneTree mSceneTree;
		Scene mGameScene;
		// Camera
		Camera mCamera;
		// Renderer
		Renderer mRenderer;

		vec3 ballColor = vec3(0.2, 0.2, 0.2);
		vec3 wallColor = vec3(.96, .96, .86);
		vec3 hpColor = vec3(0, 1, 0);

		/// Setup OpenGL and any libraries
		this(int major_ogl_version, int minor_ogl_version){

				// Setup SDL OpenGL Version
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
				// We want to request a double buffer for smooth updating.
				SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
				SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

				// Create an application window using OpenGL that supports SDL
				mWindow = SDL_CreateWindow( "dlang - OpenGL 4+ Graphics Framework",
								windowWidth,
								windowHeight,
								SDL_WINDOW_OPENGL );
				SDL_SetWindowFullscreen(mWindow, true);
				SDL_GetWindowSize(mWindow, &windowWidth, &windowHeight);

				// Create the OpenGL context and associate it with our window
				mContext = SDL_GL_CreateContext(mWindow);

				// Load OpenGL Function calls
				auto retVal = LoadOpenGLLib();

				// Check OpenGL version
				GetOpenGLVersionInfo();

				// Create a renderer
				mRenderer = new Renderer(mWindow,windowWidth,windowHeight);

				// Create a camera
				mCamera = new Camera(windowWidth, windowHeight);

				// Create (or load) a Scene Tree
				mSceneTree = new SceneTree("root");

				// CreateRenderer(mWindow);

				bool success = loadFont(50);
				if (!success) {
					writeln("Cannot load font");
				} else {
					writeln("Load fonts ok");
				}
				
		}

		/// Destructor
		~this(){
				// Destroy our context
				SDL_GL_DestroyContext(mContext);
				// Destroy our window
				SDL_DestroyWindow(mWindow);
		}

		/// Handle input
		void Input(){
				// Store an SDL Event
				SDL_Event event;
				while(SDL_PollEvent(&event)){
						if(event.type == SDL_EVENT_QUIT){
								writeln("Exit event triggered (probably clicked 'x' at top of the window)");
								mGameIsRunning= false;
						}
						if(event.type == SDL_EVENT_KEY_DOWN){
								if(event.key.scancode == SDL_SCANCODE_ESCAPE){
										writeln("Pressed escape key and now exiting...");
										mGameIsRunning= false;
								}
								if(event.key.scancode == SDL_SCANCODE_R){
										
								}
								// else if(event.key.keysym.sym == SDLK_TAB){
								// 		mRenderWireframe = !mRenderWireframe;
								// }
								// else if(event.key.keysym.sym == SDLK_DOWN){
								// 		mCamera.MoveBackward();
								// }
								// else if(event.key.keysym.sym == SDLK_UP){
								// 		mCamera.MoveForward();
								// }
								// else if(event.key.keysym.sym == SDLK_LEFT){
								// 		mCamera.MoveLeft();
								// }
								// else if(event.key.keysym.sym == SDLK_RIGHT){
								// 		mCamera.MoveRight();
								// }
								// else if(event.key.keysym.sym == SDLK_a){
								// 		mCamera.MoveUp();
								// }
								// else if(event.key.keysym.sym == SDLK_z){
								// 		mCamera.MoveDown();
								// }
								// writeln("Camera Position: ",mCamera.mEyePosition);
						}
				}


                // Retrieve the mouse position
                float mouseX,mouseY;
                SDL_GetMouseState(&mouseX,&mouseY);
				//writeln(mouseX, ", ", mouseY);
				SDL_WarpMouseInWindow(mWindow,windowWidth/2.0,windowHeight/2.0);
				int windowX, windowY;
				bool ok = SDL_GetWindowPosition(mWindow, &windowX, &windowY);
				//writeln(ok, ", ", windowX, ", ", windowY);
				//SDL_WarpMouseGlobal(windowX + windowWidth/2.0, windowY + windowHeight/2.0);
                mCamera.MouseLook(mouseX,mouseY);
				mGameScene.SetCamera(mCamera);
				// mGameScene.Input();
		}

		/// A helper function to setup a scene.
		/// NOTE: In the future this can use a configuration file to otherwise make our graphics applications
		///       data-driven.
		void SetupScene(){


				// Create a pipeline and associate it with a material
				// that can be attached to meshes.
				Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
				Pipeline lightPipeline = new Pipeline("light","./pipelines/light/basic.vert","./pipelines/light/basic.frag");
				Pipeline crossHairPipeline = new Pipeline("2d", "./pipelines/2d/2d.vert", "./pipelines/2d/2d.frag");
				Pipeline text2DPipeline = new Pipeline("2d_texture", "./pipelines/2d_texture/2d_texture.vert", "./pipelines/2d_texture/2d_texture.frag");

				IMaterial basicMaterial    = new BasicMaterial("basic");
				IMaterial ballMaterial    = new BasicMaterial("light");
				IMaterial wallMaterial    = new BasicMaterial("light");
				IMaterial hpBarMaterial    = new BasicMaterial("light");

				// Create an object and add it to our scene tree
				ISurface obj = new SurfaceOBJ("./assets/sphere.obj"); 
				MeshNode  ball        = new MeshNode("ball",obj,ballMaterial);

				ISurface lightObj = new SurfaceOBJ("./assets/cube.obj");
				MeshNode light = new MeshNode("light", lightObj, basicMaterial);

				MeshNode wall = new MeshNode("wall", lightObj, wallMaterial);
				MeshNode hpBar = new MeshNode("hpBar", lightObj, hpBarMaterial);
				mSceneTree.GetRootNode().AddChildSceneNode(ball);
				mSceneTree.GetRootNode().AddChildSceneNode(light);

				// Add three uniforms to the basic material.
				// The 4th parameter is set to the pointer where the value will be updated each frame.
				// Becauses the model matrix will be different among models, then we will just leave
				// this null for now.
				basicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				basicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				basicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

				ballMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				ballMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				ballMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
				ballMaterial.AddUniform(new Uniform("vColor", "vec3", ballColor.DataPtr()));

				wallMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				wallMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				wallMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
				wallMaterial.AddUniform(new Uniform("vColor", "vec3", wallColor.DataPtr()));

				hpBarMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				hpBarMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				hpBarMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
				hpBarMaterial.AddUniform(new Uniform("vColor", "vec3", hpColor.DataPtr()));

				mGameScene = new GameScene(ball, wall, light, hpBar, windowWidth, windowHeight);
				mCamera.mEyePosition.z = 1;
		}

		/// Update gamestate
		void Update(){
				// A rotation value that 'updates' every frame to give some animation in our scene
				static float yRotation = 0.0f;   yRotation += 0.01f;

				// Update our first object
				// MeshNode m = cast(MeshNode)mSceneTree.FindNode("ball");
				// m.mModelMatrix = MatrixMakeTranslation(vec3(0.0f,0.0f,-1.0f));
				// m.mModelMatrix = m.mModelMatrix * MatrixMakeYRotation(yRotation);

				// MeshNode l = cast(MeshNode)mSceneTree.FindNode("light");
				// l.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 1.0f, 0.0f));

				// set light variables
				
    			glUseProgram(Pipeline.sPipeline["light"]);

				GLuint loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mColor[0]");
				//writeln(loc);
				glUniform1f(loc, 0.9);
				loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mColor[1]");
				//writeln(loc);
				glUniform1f(loc, 0.9);
				loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mColor[2]");
				//writeln(loc);
				glUniform1f(loc, 0.9);

				loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mAmbientIntensity");
				//writeln(loc);
				glUniform1f(loc, 0.04);
				loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mSpecularIntensity");
				//writeln(loc);
				glUniform1f(loc, 0.0);
				loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mSpecularExponent");
				//writeln(loc);
				glUniform1f(loc, 4.0);

				// set light location
				//vec4 light_loc = l.mModelMatrix * vec4(0, 0, 0, 1);
				
				GLuint x_loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mPosition[0]");
				//writeln(x_loc);
				glUniform1f(x_loc, 0);
				
				GLuint y_loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mPosition[1]");
				glUniform1f(y_loc, 2);
				
				GLuint z_loc = glGetUniformLocation(Pipeline.sPipeline["light"], "uLight.mPosition[2]");
				glUniform1f(z_loc, 0);

				mGameScene.Update();
		}

		/// Render our scene by traversing the scene tree from a specific viewpoint
		void Render(){
				if(mRenderWireframe){
						glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
				}else{
						glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
				}

				//mRenderer.Render(mSceneTree,mCamera);

				mRenderer.Render(mGameScene, mCamera);
		}

		/// Process 1 frame
		void AdvanceFrame(){
				Input();
				Update();
				Render();
				
				// SDL_Delay(1);	// NOTE: This is a simple way to cap framerate at 60 FPS,
								// 		  you might be inclined to improve things a bit.
		}

		/// Main application loop
		void Loop(){
				// Setup the graphics scene
				SetupScene();

				// Lock mouse to center of screen
				// This will help us get a continuous rotation.
				// NOTE: On occasion folks on virtual machine or WSL may not have this work,
				//       so you'll have to compute the 'diff' and reposition the mouse yourself.

				// Run the graphics application loop
		SDL_WarpMouseInWindow(mWindow,windowWidth/2.0,windowHeight/2.0);
				while(mGameIsRunning){
						AdvanceFrame();
				}
		}
}

