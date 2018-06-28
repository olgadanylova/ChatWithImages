


import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var userNameTextField: UITextField!
    
    //    let APPLICATION_ID = "751D3222-34C7-2619-FF11-4017F65BBC00"
    //    let API_KEY = "8722B6BB-6924-87E1-FFD9-53B8C1455200"
    let APPLICATION_ID = "APP_ID"
    let API_KEY = "API_KEY"
    let SERVER_URL = "https://api.backendless.com"
    
    var userName: String?
    var channel: Channel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Backendless.sharedInstance().hostURL = SERVER_URL
        Backendless.sharedInstance().initApp(APPLICATION_ID, apiKey: API_KEY)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func showErrorAlert(_ fault: Fault) {
        let alert = UIAlertController(title: "Error", message: fault.message, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(dismissButton)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowChat") {
            let chatVC = segue.destination as! ChatViewController
            chatVC.userName = userName
            chatVC.channel = channel
        }
    }
    
    @IBAction func pressedStartChat(_ sender: Any) {
        if (!(userNameTextField.text?.isEmpty)!) {
            userName = userNameTextField.text            
            self.channel = Backendless.sharedInstance().messaging.subscribe("realtime_example")
            self.channel?.addJoinListener({
                self.performSegue(withIdentifier: "ShowChat", sender: nil)
            }, error: { fault in
                if (fault?.faultCode == "404") {
                    self.showErrorAlert(Fault(message: "Make sure to configure the app with your APP ID and API KEY before running the app. \nApplication will be closed"))
                }
                else {
                    self.showErrorAlert(fault!)
                }
            })
        }
        else {
            showErrorAlert(Fault(message: "Please enter user name"))
        }
    }
}

