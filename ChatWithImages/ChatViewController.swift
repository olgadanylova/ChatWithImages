
import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var messageInputField: UITextField!
    
    var channel: Channel?
    private var currentUser: BackendlessUser?
    private var userName: String?
    private var editMode = false
    private var editingMessage: ChatMessage?
    private var activeTextField: UITextField?
    private var messages: Array<ChatMessage>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = Backendless.sharedInstance().userService.currentUser
        userName = currentUser?.email as String?
        addListeners()
        messages = Array<ChatMessage>()        
        let message = ChatMessage()
        message.userName = userName
        message.messageText = "joined"
        Backendless.sharedInstance().messaging.publish(self.channel?.channelName, message: message, response: { messageStatus in
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageInputField.delegate = self
        navigationItem.title = userName
        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = nil
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        removeListeners()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        let infoValue = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = infoValue.cgRectValue.size
        UIView.animate(withDuration: 0.3, animations: {
            var viewFrame = self.view.frame
            viewFrame.size.height -= keyboardSize.height
            self.view.frame = viewFrame
        })
        if (self.tableView.numberOfRows(inSection: 0) > 0) {
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc func keyboardWillBeHidden(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: {
            let screenFrame = UIScreen.main.bounds
            var viewFrame = CGRect(x: 0, y: 0, width: screenFrame.size.width, height: screenFrame.size.height)
            viewFrame.origin.y = 0
            self.view.frame = viewFrame
        })
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        if (editMode) {
            textField.returnKeyType = .done
        }
        else {
            textField.returnKeyType = .send
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (!editMode) {
            if (!(messageInputField.text?.isEmpty)!) {
                let message = ChatMessage()
                message.userName = userName
                message.messageText = messageInputField.text
                publishMessage(message)
                messageInputField.text = ""
            }
        }
        else {
            if (!(messageInputField.text?.isEmpty)!) {
                editingMessage?.messageText = messageInputField.text
                Backendless.sharedInstance().data.of(ChatMessage.ofClass()).save(editingMessage, response: { updatedMessage in
                    self.editingMessage = nil
                    self.editMode = false
                }, error: { fault in
                    self.showErrorAlert(fault!)
                })
                messageInputField.text = ""
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (messages?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.messages![indexPath.row]
        if (message.messageText != nil) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            cell.nameLabel.text = String(format: "[%@]:", message.userName!)
            cell.messageLabel.text = message.messageText
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTapOnTextMessage(_:))))
            return cell
        }
        else if (message.pictureUrl != nil) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PictureCell", for: indexPath) as! PictureCell
            cell.nameLabel.text = String(format: "[%@]:", message.userName!)
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTapOnPicture(_:))))
            if (message.picture != nil) {
                cell.pictureView.image = message.picture
            }
            else {
                cell.pictureView.image = nil
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
                let url = URL(string: message.pictureUrl!)!
                let session = URLSession(configuration: .default)
                let downloadPictureTask = session.dataTask(with: url) { (data, response, error) in
                    if let imageData = data {
                        let image = UIImage(data: imageData)
                        message.picture = image
                        DispatchQueue.main.async {
                            cell.pictureView.image = image
                            cell.activityIndicator.isHidden = true
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                }
                downloadPictureTask.resume()
            }      
            return cell
        }
        return UITableViewCell()
    }
    
    @IBAction func longTapOnTextMessage(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let touch = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touch) {
                let message = messages![indexPath.row]
                if (message.ownerId == currentUser?.objectId as String? ) {
                    let alert = UIAlertController(title: "\(message.messageText ?? "")", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { alertAction in
                        self.editMode = true
                        self.editingMessage = message
                        self.messageInputField.text = message.messageText
                        self.messageInputField.becomeFirstResponder()
                    }))
                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
                        let confirmAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this message?", preferredStyle: .alert)
                        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { alertAction in
                            Backendless.sharedInstance().data.of(ChatMessage.ofClass()).remove(byId:message.objectId, response: { removed in
                            }, error: { fault in
                                self.showErrorAlert(fault!)
                            })
                        }))
                        confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                        self.present(confirmAlert, animated: true)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func longTapOnPicture(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
            let touch = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touch) {
                let message = messages![indexPath.row]
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                if (message.ownerId == currentUser?.objectId as String? ) {
                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
                        let confirmAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this message?", preferredStyle: .alert)
                        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { alertAction in
                            Backendless.sharedInstance().data.of(ChatMessage.ofClass()).remove(byId:message.objectId, response: { removed in
                            }, error: { fault in
                                self.showErrorAlert(fault!)
                            })
                        }))
                        confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                        self.present(confirmAlert, animated: true)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Save to gallery", style: .default, handler: { action in
                    UIImageWriteToSavedPhotosAlbum(message.picture!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showErrorAlert(Fault(message: error.localizedDescription))
        } else {
            let alert = UIAlertController(title: "Saved", message: "Image has been saved to your photos", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    func addListeners() {
        channel?.addMessageListenerCustomObject({ receivedMessage in
            if let message = receivedMessage as? ChatMessage {
                self.messages?.append(message)
                self.tableView.reloadData()
            }
        }, error: { fault in
            self.showErrorAlert(fault!)
        }, class: ChatMessage.ofClass())
        
        Backendless.sharedInstance().data.of(ChatMessage.ofClass()).rt.addUpdateListener({ updatedMessage in
            if let message = self.messages?.filter({$0.objectId == (updatedMessage as! ChatMessage).objectId}).first {
                let index = self.messages?.index(of: message)
                self.messages![index!] = updatedMessage as! ChatMessage
                self.tableView.reloadData()
            }
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
        
        Backendless.sharedInstance().data.of(ChatMessage.ofClass()).rt.addDeleteListener({ deletedMessage in
            if let message = self.messages?.filter({$0.objectId == (deletedMessage as! ChatMessage).objectId}).first {
                let index = self.messages?.index(of: message)
                self.messages?.remove(at: index!)
                self.tableView.reloadData()
            }
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
    }
    
    func removeListeners() {
        channel?.removeAllListeners()
        Backendless.sharedInstance().data.of(ChatMessage.ofClass()).rt.removeAllListeners()
    }
    
    func publishMessage(_ message: ChatMessage) {
        Backendless.sharedInstance().data.of(ChatMessage.ofClass()).save(message, response: { savedMessage in
            Backendless.sharedInstance().messaging.publish(self.channel?.channelName, message: savedMessage, response: { messageStatus in
            }, error: { fault in
                self.showErrorAlert(fault!)
            })
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
        
    }
    
    func showErrorAlert(_ fault: Fault) {
        let alert = UIAlertController(title: "Error", message: fault.message, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(dismissButton)
        present(alert, animated: true, completion: nil)
    }
    
    func showImagePicker() {
        let alert = UIAlertController(title: "Select image", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Use camera", style: .default, handler: { alertAction in
            if (!UIImagePickerController.isSourceTypeAvailable(.camera)) {
                let fault = Fault(message: "No device found. Camera is not available")
                self.showErrorAlert(fault!)
            }
            else {
                let cameraPicker = UIImagePickerController()
                cameraPicker.sourceType = .camera
                cameraPicker.delegate = self
                self.present(cameraPicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Select from gallery", style: .default, handler: { alertAction in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let img = UIImage(cgImage: (image?.cgImage)!, scale: CGFloat(1.0), orientation: .right)
        let imagePath = String(format: "tmpChatFiles/%@.png", UUID().uuidString)
        Backendless.sharedInstance().file.uploadFile(imagePath, content: UIImagePNGRepresentation(img), response: { uploadedPicture in
            let message = ChatMessage()
            message.userName = self.userName
            message.pictureUrl = uploadedPicture?.fileURL
            self.publishMessage(message)
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func attachFile(_ sender: Any) {
        view.endEditing(true)
        showImagePicker()
    }
    
    @IBAction func logout(_ sender: Any) {
        Backendless.sharedInstance().userService.logout({
            self.performSegue(withIdentifier: "unwindToVC", sender: nil)
        }, error: { fault in
            self.showErrorAlert(fault!)
        })
    }
}
