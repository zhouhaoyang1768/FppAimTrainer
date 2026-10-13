/// This represents a camera abstraction.
module camera;

import linear;
import bindbc.sdl;
import bindbc.opengl;
import std.math.trigonometry;

/// Camera abstraction.
class Camera{
    int window_width;
    int window_height;

    float wh_ratio;

    float mLastMouseX;
    float mLastMouseY;
    mat4 mViewMatrix;
    mat4 mProjectionMatrix;

    vec3 mEyePosition;          /// This is our 'translation' value
    // Axis of the camera
    vec3 mUpVector;             /// This is 'up' in the world
    vec3 mForwardVector;        /// This is on the camera axis
    vec3 mRightVector;          /// This is where 'right' is

    float mXAngle;
    float mYAngle;
    /// Constructor for a camera
    this(int w, int h){
        window_width = w;
        window_height = h;

        // Setup our camera (view matrix) 
        mViewMatrix = MatrixMakeIdentity();

        // Setup our perspective projection matrix
        // NOTE: Assumption made here is our window is always 640/480 or the similar aspect ratio.
        mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians,(cast(double)window_width)/window_height, 0.1f, 100.0f);

        /// Initial Camera setup
        mEyePosition    = vec3(0.0f, 0.0f, 0.0f);
        // Eye position
        // Forward vector matching the positive z-axis
        mForwardVector  = vec3(0.0f, 0.0f, 1.0f);
        // Where up is in the world initially
        mUpVector       = vec3(0.0f,1.0f,0.0f);
        // Where right is initially
        mRightVector    = vec3(1.0f, 0.0f, 0.0f);

        mXAngle = 0;
        mYAngle = 0;
        
        SDL_GetMouseState(&mLastMouseX,&mLastMouseY);

    }

    /// Position the eye of the camera in the world
    void SetCameraPosition(vec3 v){
        UpdateViewMatrix();
        mEyePosition = v;
    }
    /// Position the eye of the camera in the world
    void SetCameraPosition(float x, float y, float z){
        UpdateViewMatrix();
        mEyePosition = vec3(x,y,z);
    }

    /// Builds a matrix for where the matrix is looking
    /// given the following parameters
    mat4 LookAt(vec3 eye, vec3 direction, vec3 _up){
        // TODO

        // Note: I would recommend handling this in 2 parts
        //       1. First try handling translation (Remember camera moves opposite of world)
        //       2. Then add the 'look' vector that handles rotation.
        // 
        // Consider which matrix you need to transpose in order to 'invert'
        // the operation.

        mat4 translation;
        translation[0, 3] = -eye[0];
        translation[1, 3] = -eye[1];
        translation[2, 3] = -eye[2];

        mat4 rotation;

        vec3 forward = eye - direction;
        vec3 right = Cross(_up, forward);
        vec3 up = Cross(forward, right);

        rotation[0, 0] = right[0];
        rotation[0, 1] = right[1];
        rotation[0, 2] = right[2];
        rotation[1, 0] = up[0];
        rotation[1, 1] = up[1];
        rotation[1, 2] = up[2];
        rotation[2, 0] = forward[0];
        rotation[2, 1] = forward[1];
        rotation[2, 2] = forward[2];

        mEyePosition = eye;
        mUpVector = Normalize(_up);
        mForwardVector = Normalize(forward);
        mRightVector = Normalize(right); 

        return rotation * translation; 
    }

    /// Sets the view matrix and also retrieves it
    /// Retrieves the camera view matrix
    mat4 UpdateViewMatrix(){
        mViewMatrix = LookAt(mEyePosition,
                             mEyePosition - mForwardVector,
                             mUpVector);
        return mViewMatrix;
    }

    /// Mouse look function
    void MouseLook(float mouseX, float mouseY){
        const float ratio = 0.0006;
        float dx = mouseX - window_width / 2.0;
        float dy = mouseY - window_height / 2.0;
        

        dx *= -1;
        dy *= -1;

        float angleY = dx * ratio;
        float angleX = dy * ratio;
        import std.stdio;

        mXAngle += angleX;
        mYAngle += angleY;

        import std.math;
        if (mXAngle > PI / 2) mXAngle = PI / 2;
        if (mXAngle < -PI / 2) mXAngle = -PI / 2;

        mat3 rotation = MatrixMakeYRotation(mYAngle) * MatrixMakeXRotation(mXAngle);

        
        mForwardVector = rotation * vec3(0, 0, 1);
        mUpVector = rotation * vec3(0, 1, 0);
        mRightVector = rotation * vec3(1, 0, 0);



        UpdateViewMatrix();
        mLastMouseX = mouseX;
        mLastMouseY = mouseY;
    }
    static const float dx = 0.1;
    void MoveForward(){
        mEyePosition = mEyePosition - mForwardVector * dx;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveBackward(){
        mEyePosition = mEyePosition + mForwardVector * dx;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveLeft(){
        mEyePosition = mEyePosition - mRightVector * dx;
        UpdateViewMatrix();
        // TODO 
    }

    void MoveRight(){
        mEyePosition = mEyePosition + mRightVector * dx;
        UpdateViewMatrix();
        // TODO 
    }
    
    void MoveUp(){
        
        mEyePosition = mEyePosition + vec3(0, 1, 0) * dx;
        UpdateViewMatrix();
        // TODO 
        SetCameraPosition(mEyePosition.x, 
					     						 mEyePosition.y +1.0f,
						  						 mEyePosition.z);
    }

    void MoveDown(){
        mEyePosition = mEyePosition + vec3(0, -1, 0) * dx;
        UpdateViewMatrix();
        // TODO 
        SetCameraPosition(mEyePosition.x, 
					     						 mEyePosition.y - 1.0f,
						  						 mEyePosition.z);
    }
}
