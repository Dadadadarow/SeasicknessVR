using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyWaterBuoyancy;

public class TaskManager : MonoBehaviour
{
    public GameObject canvasObject;
    public bool isMove = true;
    public WaterWaves waterWaves;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (OVRInput.GetDown(OVRInput.Button.Two))
        {
            if (waterWaves.speed != 0)
            {
                // canvasObject.SetActive(false);
                waterWaves.speed = 0f;
                waterWaves.height = 0f;
                isMove = false;
            }
            else
            {
                // canvasObject.SetActive(true);
                waterWaves.speed = 3f;
                waterWaves.height = 0.3f;
                isMove = true;
            }
        }
        if (OVRInput.GetDown(OVRInput.Button.One))
        {
            if (canvasObject.activeSelf)
            {
                canvasObject.SetActive(false);
            }
            else
            {
                canvasObject.SetActive(true);
            }
        }
    }
}
