using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using NaughtyWaterBuoyancy;

public class SliderManager : MonoBehaviour
{
    public WaterWaves waveData;
    Slider waveSlider;
    // Start is called before the first frame update
    void Start()
    {
        waveSlider = GetComponent<Slider>();

        float maxWave = 10f;
        float nowWave = 2f;

        waveSlider.maxValue = maxWave;
        waveSlider.value = nowWave;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void Method()
    {
        waveData.speed = waveSlider.value;
    }
}
