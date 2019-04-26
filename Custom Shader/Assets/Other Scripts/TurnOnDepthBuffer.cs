using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TurnOnDepthBuffer : MonoBehaviour {

	// Use this for initialization
	void Start () {
        // Prepare camera to generate depth map for shadows to sample from
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
        GetComponent<Camera>().clearFlags = CameraClearFlags.Skybox;
        GetComponent<Camera>().backgroundColor = Color.white;
        GetComponent<Camera>().renderingPath = RenderingPath.Forward;
        GetComponent<Camera>().SetReplacementShader(Shader.Find("DepthMapGen"), "RenderType");
        GetComponent<Camera>().enabled = false;
    }
}
