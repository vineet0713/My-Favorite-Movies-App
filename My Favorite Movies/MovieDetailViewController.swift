//
//  MovieDetailViewController.swift
//  My Favorite Movies
//
//  Created by Vineet Joshi on 2/4/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var isFavorite = false
    var movie: Movie?
    
    // MARK: Outlets
    
    @IBOutlet weak var detailMoviePoster: UIImageView!
    @IBOutlet weak var detailMovieTitle: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = movie {
            getFavorite()
        }
    }
    
    func getFavorite() {
        // set defaults
        detailMoviePoster.image = nil
        detailMovieTitle.text = movie!.title
        
        /* TASK A: Get favorite movies, then update the favorite buttons */
        /* 1A. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        /* 4A. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request as URLRequest) { (data, response, error) in
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5A. Parse the data */
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let results = parsedResult[Constants.TMDBResponseKeys.Results] as? [[String:AnyObject]] else {
                print("Cannot find key '\(Constants.TMDBResponseKeys.Results)' in \(parsedResult)")
                return
            }
            
            /* 6A. Use the data! */
            let movies = Movie.moviesFromResults(results)
            self.isFavorite = false
            
            for movie in movies {
                if movie.id == self.movie!.id {
                    self.isFavorite = true
                }
            }
            
            performUIUpdatesOnMain {
                self.updateUI()
            }
        }
        
        /* 7A. Start the request */
        task.resume()
        
        /* TASK B: Get the poster image, then populate the image view */
        if let _ = movie!.posterPath {
            self.getPosterImage()
        }
    }
    
    func getPosterImage() {
        /* 1B. Set the parameters */
        // There are none...
        
        /* 2B. Build the URL */
        let baseURL = URL(string: appDelegate.config.baseImageURLString)!
        let url = baseURL.appendingPathComponent("w342").appendingPathComponent(movie!.posterPath!)
        
        /* 3B. Configure the request */
        let request = URLRequest(url: url)
        
        /* 4B. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5B. Parse the data */
            // No need, the data is already raw image data.
            
            /* 6B. Use the data! */
            if let image = UIImage(data: data) {
                performUIUpdatesOnMain {
                    self.detailMoviePoster.image = image
                }
            }
        }
        
        /* 7B. Start the request */
        task.resume()
    }
    
    @IBAction func modifyFavorite(_ sender: Any) {
        let shouldFavorite = !isFavorite
        
        /* TASK: Add movie as favorite, then update favorite button */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/account/\(appDelegate.userID!)/favorite"))
        
        request.httpMethod = "POST"
        
        // the "Accept" header tells the API that we will accept JSON in the response (the data that comes back to us)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // the "Content-Type" header tells the API that the data we'll send in the HTTP body will be treated like JSON
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = "{\"media_type\": \"movie\",\"media_id\": \(movie!.id),\"favorite\":\(shouldFavorite)}".data(using: String.Encoding.utf8)
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request as URLRequest) { (data, response, error) in
            guard (error == nil) else {
                print(error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5. Parse the data */
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON.")
                return
            }
            
            guard let tmdbStatusCode = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int else {
                print("Could not find key '\(Constants.TMDBResponseKeys.StatusCode)'")
                return
            }
            
            if shouldFavorite && !(tmdbStatusCode == 12 || tmdbStatusCode == 1) {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)'")
                return
            } else if !shouldFavorite && tmdbStatusCode != 13 {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)'")
                return
            }
            
            /* 6. Use the data! */
            self.isFavorite = shouldFavorite
            
            performUIUpdatesOnMain {
                self.updateUI()
            }
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    // MARK: Update UI
    
    func updateUI() {
        if isFavorite {
            favoriteButton.tintColor = UIColor.red
            favoriteButton.setTitle("Remove Favorite", for: .normal)
        } else {
            favoriteButton.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            favoriteButton.setTitle("Add Favorite", for: .normal)
        }
    }
}
