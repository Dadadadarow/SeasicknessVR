using UnityEngine;

public class BoatController : MonoBehaviour
{
    public float forwardForce = 100f; // 前進の力
    public float backwardForce = 5f; // 後退の力
    public float rotationSpeed = 100f; // 回転の速度

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        // 方向キーの入力を受け取る
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");

        // 前進方向への力を加える
        if (verticalInput > 0)
        {
            Debug.Log("forward detected.");
            rb.AddForce(transform.forward * forwardForce * verticalInput);
        }
        // 後退方向への力を加える
        else if (verticalInput < 0)
        {
            Debug.Log("back detected.");
            rb.AddForce(-transform.forward * backwardForce * Mathf.Abs(verticalInput));
        }

        // 船の回転
        rb.AddTorque(transform.up * rotationSpeed * horizontalInput);
    }
}

