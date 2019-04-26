using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Helicopter : MonoBehaviour {
    // Starting y rotation of the helicopter and the angle the helicopter rotates between
    public float startRotation = -50;
    public float rotateAngle = 30;

    // Animation of the helicopter
    private Animation anim;

	// Use this for initialization
	void Start () {
        // Get the animation
        anim = GetComponent<Animation>();
	}
	
	// Update is called once per frame
	void Update () {
        // If animation isn't playing then play
        if (!anim.isPlaying)
            anim.Play();

        // Rotate the helicopter by the angle over 2 seconds (linked to the sine of the time)
        Vector3 rotation = transform.rotation.eulerAngles;
        rotation.y = Mathf.Sin(Time.time) * (rotateAngle / 2) + startRotation;
        transform.rotation = Quaternion.Euler(rotation);
	}
}
