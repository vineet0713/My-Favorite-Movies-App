//
//  LoginViewController.swift
//  My Favorite Movies
//
//  Created by Vineet Joshi on 2/3/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit

// Big difference between Flickr API and TMDB API:
// The methods of TMDB API are specified as part of the URL path (like http://api.themoviedatabase.org/3/account)
// The methods of Flickr API are specified as part of the URL's query (like method=flickr.photos.search)

class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    //var appDelegate: AppDelegate!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: Outlets
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        usernameField.becomeFirstResponder()
    }
    
    // MARK: Login
    
    @IBAction func login(_ sender: Any) {
        if (usernameField.text?.isEmpty)! || (passwordField.text?.isEmpty)! {
            let alert = UIAlertController(title: "Empty Username or Password", message: "Please enter your username and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"Empty Username or Password\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            /*
             Steps for Authentication...
             https://www.themoviedb.org/documentation/api/sessions
             
             Step 1: Create a request token
             Step 2: Ask the user for permission via the API ("login")
             Step 3: Create a session ID
             
             Extra Steps...
             Step 4: Get the user id
             Step 5: Go to the next view!
             */
            getRequestToken(username: usernameField.text!, password: passwordField.text!)
        }
    }
    
    // MARK: TheMovieDB
    
    private func getRequestToken(username: String, password: String) {
        
        /* TASK: Get a request token, then store it (appDelegate.requestToken) and login with the token */
        
        /* 1. Set the parameters */
        // the only parameter that's needed is the API key!
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/authentication/token/new"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            /* 5. Parse the data */
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode <= 299) else {
                print("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                print("No data was returned.")
                return
            }
            
            var parsedResult: [String:Any]
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                print("Could not parse the data as JSON.")
                return
            }
            
            guard let requestToken = parsedResult[Constants.TMDBResponseKeys.RequestToken] as? String else {
                print("Could not parse request token.")
                return
            }
            
            /* 6. Use the data! */
            // print("Request Token: \(requestToken)")
            self.appDelegate.requestToken = requestToken
            self.loginWithToken(requestToken, username, password)
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    private func loginWithToken(_ requestToken: String, _ username: String, _ password: String) {
        
        /* TASK: Login, then get a session id */
        
        /* 1. Set the parameters */
        // the parameters needed are the API key and request token
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.Username: username,
            Constants.TMDBParameterKeys.Password: password,
            Constants.TMDBParameterKeys.RequestToken: requestToken
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String : AnyObject], withPathExtension: "/authentication/token/validate_with_login"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            /* 5. Parse the data */
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            guard let data = data else {
                print("No data was returned.")
                return
            }
            
            var parsedData: [String:Any]
            
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                print("Could not parse the data as JSON.")
                return
            }
            
            guard let _ = parsedData[Constants.TMDBResponseKeys.Success] as? Bool else {
                print("Cannot find key \(Constants.TMDBResponseKeys.Success).")
                performUIUpdatesOnMain {
                    let alert = UIAlertController(title: "Login Failed", message: "Invalid username or password. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                        NSLog("The \"Login Failed\" alert occured.")
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            /* 6. Use the data! */
            self.getSessionID(requestToken)
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    private func getSessionID(_ requestToken: String) {
        
        /* TASK: Get a session ID, then store it (appDelegate.sessionID) and get the user's id */
        
        /* 1. Set the parameters */
        // the parameters needed are the API key and request token
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.RequestToken: requestToken
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String : AnyObject], withPathExtension: "/authentication/session/new"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            /* 5. Parse the data */
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode <= 299) else {
                print("The request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                print("No data was returned.")
                return
            }
            
            var parsedData: [String:Any]
            
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                print("Could not parse the data as JSON.")
                return
            }
            
            guard let sessionId = parsedData[Constants.TMDBResponseKeys.SessionID] as? String else {
                print("Could not find key \(Constants.TMDBResponseKeys.SessionID).")
                return
            }
            
            /* 6. Use the data! */
            // print("Session ID: \(sessionId)")
            self.appDelegate.sessionID = sessionId
            self.getUserID(sessionId)
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    private func getUserID(_ sessionID: String) {
        
        /* TASK: Get the user's ID, then store it (appDelegate.userID) for future use and go to next view! */
        
        /* 1. Set the parameters */
        // the parameters needed are the API key and request token
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: sessionID
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String : AnyObject], withPathExtension: "/account"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            /* 5. Parse the data */
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode <= 299) else {
                print("The request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                print("No data was returned.")
                return
            }
            
            var parsedData: [String:Any]
            
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                print("Could not parse the data as JSON.")
                return
            }
            
            guard let userId = parsedData[Constants.TMDBResponseKeys.UserID] as? Int else {
                print("Could not find key \(Constants.TMDBResponseKeys.UserID).")
                return
            }
            
            /* 6. Use the data! */
            // print("User ID: \(userId)")
            self.appDelegate.userID = userId
            performUIUpdatesOnMain {
                self.completeLogin()
            }
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    func completeLogin() {
        usernameField.text = ""
        passwordField.text = ""
        performSegue(withIdentifier: "loginComplete", sender: self)
    }
    
}
