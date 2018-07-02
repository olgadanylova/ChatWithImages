


import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var userNameTextField: UITextField!
    
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
    
    func showErrorAlert(_ fault: Fault, _ exitApp: Bool) {
        let alert = UIAlertController(title: "Error", message: fault.message, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
            if (exitApp) {
                exit(0)
            }
        })
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
        view.endEditing(true)
        // just a simple check to find out if Backendless init was successful
        Backendless.sharedInstance().userService.describeUserClass({ result in
            DispatchQueue.main.async {
                if (!(self.userNameTextField.text?.isEmpty)!) {
                    self.userName = self.userNameTextField.text
                    self.channel = Backendless.sharedInstance().messaging.subscribe("realtime_example")
                    self.channel?.addJoinListener({
                        self.performSegue(withIdentifier: "ShowChat", sender: nil)
                    }, error: { fault in
                        self.showErrorAlert(fault!, false)
                    })
                }
                else {
                    self.showErrorAlert(Fault(message: "Please enter user name"), false)
                }
            }           
        }, error: { fault in
            if (fault?.faultCode == "404") {
                self.showErrorAlert(Fault(message: "Make sure to configure the app with your APP ID and API KEY before running the app. \nApplication will be closed"), true)
            }
            else {
                self.showErrorAlert(fault!, false)
            }
        })
    }
}

