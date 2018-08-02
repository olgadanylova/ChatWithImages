
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var startChatButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!    
    
    let APPLICATION_ID = "APP_ID"
    let API_KEY = "API_KEY"
    let SERVER_URL = "https://api.backendless.com"
    
    var userName: String?
    var channel: Channel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Backendless.sharedInstance().hostURL = SERVER_URL
        Backendless.sharedInstance().initApp(APPLICATION_ID, apiKey: API_KEY)
        activityIndicator.isHidden = true
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
            chatVC.channel = channel
        }
    }
    
    func login() {
        startChatButton.isEnabled = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        if (!(userNameTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)!) {
            Backendless.sharedInstance().userService.login(userNameTextField.text, password: passwordTextField.text, response: { user in
                self.userName = self.userNameTextField.text
                self.channel = Backendless.sharedInstance().messaging.subscribe("realtime_example")
                self.channel?.addJoinListener({
                    self.startChatButton.isEnabled = true
                    self.activityIndicator.stopAnimating()
                    self.performSegue(withIdentifier: "ShowChat", sender: nil)
                }, error: { fault in
                    self.startChatButton.isEnabled = true
                    self.activityIndicator.stopAnimating()
                    self.showErrorAlert(fault!, false)
                })
            }, error: { fault in
                if (fault?.faultCode == "404") {
                    self.startChatButton.isEnabled = true
                    self.activityIndicator.stopAnimating()
                    self.showErrorAlert(Fault(message: "Make sure to configure the app with your APP ID and API KEY before running the app. \nApplication will be closed"), true)
                }
                else {
                    self.startChatButton.isEnabled = true
                    self.activityIndicator.stopAnimating()
                    self.showErrorAlert(fault!, false)
                }
            })
        }
        else {
            self.showErrorAlert(Fault(message: "Please enter login and password"), false)
        }
    }
    
    @IBAction func pressedStartChat(_ sender: Any) {
        view.endEditing(true)
        login()
        userNameTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func unwindToViewController(segue:UIStoryboardSegue) {
    }
}

