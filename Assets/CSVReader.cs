using UnityEngine;
using System.Collections;
using System.IO;

public class CSVReader : MonoBehaviour
{
    public string folderPath = "Assets/Resources/EEG/VieOutput"; // フォルダのパス
    public string fileExtension = "csv"; // ファイルの拡張子

    private string[] filePaths;
    private int currentLineIndex = 0;

    void Start()
    {
        // フォルダ内のCSVファイルを取得
        filePaths = Directory.GetFiles(folderPath, $"VieRawData.{fileExtension}");

        // ファイルが存在しない場合はエラーを表示
        if (filePaths.Length == 0)
        {
            Debug.LogError($"No CSV files found in {folderPath}");
            return;
        }

        // ファイルの読み込み
        ReadFile(filePaths[0]); // 最初のファイルを読み込む
    }

    void Update()
    {
        // キー入力で次の行を読み込む
        if (Input.GetKeyDown(KeyCode.K))
        {
            ReadNextLine();
        }
    }

    void ReadFile(string filePath)
    {
        try
        {
            // ファイルのテキストをすべて読み込む
            string[] lines = File.ReadAllLines(filePath);

            // ファイルの内容をログに表示
            foreach (string line in lines)
            {
                Debug.Log(line);
            }
        }
        catch
        {

        }
    }

    void ReadNextLine()
    {
        // ファイルが存在しない場合はエラーを表示
        if (filePaths.Length == 0)
        {
            Debug.LogError($"No CSV files found in {folderPath}");
            return;
        }

        // 現在の行が最後の行に達したら最初の行に戻る
        if (currentLineIndex >= filePaths.Length)
        {
            currentLineIndex = 0;
        }

        // 現在の行のファイルを読み込む
        ReadFile(filePaths[currentLineIndex]);

        // 次の行に進む
        currentLineIndex++;
    }
}
