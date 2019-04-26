using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Manager : MonoBehaviour {
    // Singleton setup
    public static Manager instance = null;

    // Maximum intensity of the Sun
    public float maxIntensity = 0.75f;

    // Lights in the scene
    public Light[] lights;

    // Main camera in the scene
    public Camera mainCamera;

    // Cameras in the scene
    private Camera[] cameras;

    private Tree[] trees;

    // Player's character
    public GameObject player;

    // Lenght of time it takes the sun to complete a full cycle
    private float cycleLength;

    void Awake() {
        // Singleton setup. If there isn't an instance, make this the instance, otherwise destroy this.
        if (instance == null)
            instance = this;
        else if (instance != this)
            Destroy(gameObject);

        // Find all the lights in the scene
        lights = FindObjectsOfType<Light>();

        cameras = FindObjectsOfType<Camera>();
        trees = FindObjectsOfType<Tree>();
    }

    // Use this for initialization
    void Start () {
        // Set the cycle length so the sun take ~2 seconds to complete a cycle
        cycleLength = 360 / (Mathf.PI * 4);
    }
	
	// Update is called once per frame
	void Update () {
        // For all the depth cameras, rotate all the trees so they're faceing the camera, then render the texture,
        // then rotate the tree back to its original rotation
        foreach (Camera camera in cameras) {
            if (camera.depthTextureMode == DepthTextureMode.Depth) {
                float[] y = new float[trees.Length];
                for (int i = 0; i < trees.Length; i++) {
                    Vector3 camPos = camera.transform.position;
                    camPos.y = trees[i].transform.position.y;
                    y[i] = Vector3.SignedAngle(-trees[i].transform.forward, camPos - trees[i].transform.position, trees[i].transform.up);
                    trees[i].transform.Rotate(new Vector3(0, y[i], 0));
                }

                camera.enabled = true;
                camera.Render();
                camera.enabled = false;

                for (int i = 0; i < trees.Length; i++) {
                    trees[i].transform.Rotate(new Vector3(0, -y[i], 0));
                }
            }
        }

        // Find the directional light then move in a circular motion with the time, keeping the direction facing the center
        foreach (Light light in lights) {
            if (light.type.Equals(LightType.Directional)) {
                Vector3 direction = light.transform.forward;

                light.transform.Rotate(transform.right, cycleLength * Time.deltaTime);

                Vector3 pos = light.transform.position;
                pos.z = Mathf.Sin(Time.time / 2) * 30;
                pos.y = Mathf.Cos(Time.time / 2) * 30;
                light.transform.position = pos;

                // Decrease the light intensity as the sun sets. Don't let the sun intensity drop below 0
                if (light.transform.position.z > 0) {
                    light.intensity -= maxIntensity * 4 * Time.deltaTime / (Mathf.PI * 4);
                    if (light.intensity < 0)
                        light.intensity = 0;
                }

                // Increase the light intensity as the sun rises. Don't let the sun get brighter than the max intensity
                if (light.transform.position.z < 0) {
                    light.intensity += maxIntensity * 4 * Time.deltaTime / (Mathf.PI * 4);
                    if (light.intensity > maxIntensity)
                        light.intensity = maxIntensity;
                }

                // Make sure the intensity is 0 when the sun is below the horizon
                if (light.transform.position.y < 0)
                    light.intensity = 0;
            }
        }
    }

    /// <summary>
    /// Method to get the lights in the scene
    /// </summary>
    /// <returns>The lights in the scene</returns>
    public Light[] GetLights() {
        return lights;
    }

    /// <summary>
    /// Method to get the main camera in the scene
    /// </summary>
    /// <returns>The scene's main camera</returns>
    public Camera GetCamera() {
        return mainCamera;
    }
}
