using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Tree : MonoBehaviour {
	// Use this for initialization
	void Start () {

	}
	
	// Update is called once per frame
	void Update () {
        // Get the player's position
        Vector3 playerPos = Manager.instance.player.transform.position;
        playerPos.y = transform.position.y;

        // Find the angle between the front of the tree and the vector towards the player, then rotate by the angle
        float angle = Vector3.SignedAngle(-transform.forward, playerPos - transform.position, transform.up);

        transform.Rotate(new Vector3(0, angle, 0));
	}
}
