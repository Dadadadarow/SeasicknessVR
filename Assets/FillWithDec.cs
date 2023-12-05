using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FillWithDec : MonoBehaviour
{
    public TCPHandler tcpHandler;
    public float _min;
    public float _max;
    public bool _moveWithSight = true;
    public float _speed = 1f;
    private float _normalizedValue;
    private float _axisFloat;
	[SerializeField] private float _lerpValue;
    private Image _image;

    void Start()
    {
        _image = GetComponent<Image>();
        _normalizedValue = _max - _min;
		_lerpValue = _image.fillAmount;

    }


    void Update()
    {
        if (_moveWithSight)
        {
            float _ratio = 100/_normalizedValue;
            _axisFloat = tcpHandler.decodedValue;
            // _axisFloat = Random.Range(60f, 100f);
            // Debug.Log(_axisFloat);
            float _value = Mathf.Clamp(_axisFloat/_ratio, _min, _max);

            _lerpValue = Mathf.MoveTowards(_lerpValue, _value, _speed * Time.deltaTime);
			_image.fillAmount = _lerpValue;
        }
    }

    public void FillSprite(float f)
    {
        _image.fillAmount = f;
    }
}
