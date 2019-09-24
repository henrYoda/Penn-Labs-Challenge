//
//  ContentView.swift
//  Penn Labs Challenge
//
//  Created by Henrique Lorente on 9/22/19.
//  Copyright © 2019 Henrique Lorente. All rights reserved.
//

import SwiftUI
import URLImage
import WebKit
import Combine


//This is a class that will manage downloading the JSON information from the API, and formatting it correctly
//to be displayed in the app. Some weird syntax used by SwiftUI to notify the view using this object to update
//when this class' contents are updated
class NetworkManager: ObservableObject{
    var objectWillChange = PassthroughSubject<NetworkManager, Never>()
    
    //Use this array to store all of the residential dining options information
    var residentialVenues = [Venue](){
        willSet{
            objectWillChange.send(self)
        }
    }
    //Use this array to store all of the retail dining options information
    var retailVenues = [Venue](){
        willSet{
            objectWillChange.send(self)
        }
    }
    //Download the JSON from the API when this class is initialized
    init(){
        guard let url = URL(string: "http://api.pennlabs.org/dining/venues") else {return}
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return }
            do{
                //Get the data response
                let jsonResponse = try JSONSerialization.jsonObject(with:
                    dataResponse, options: [])
                
                
                //Going through the JSON to get at the information we are interested in
                guard let jsonArray = jsonResponse as? [String: Any] else {
                    return
                }
                
                guard let document = jsonArray["document"] as? [String: Any] else{
                    return
                }
                
                guard let venueArray = document["venue"] as? [[String: Any]] else{
                    return
                }
                
                //Arrays that we will eventually set the higher level class variables to
                var residentialVenues = [Venue]()
                var retailVenues = [Venue]()
                
                for venue in venueArray {
                    guard let imageURL = venue["imageUrl"] as? String else{
                        continue
                    }
                    guard let name = venue["name"] as? String else{
                        continue
                    }
                    
                    guard let facilityUrl = venue["facilityURL"] as? String else{
                        continue
                    }
                    
                    guard let venueType = venue["venueType"] as? String else{
                        continue
                    }
                    
                    guard let dateHoursArray = venue["dateHours"] as? [[String: Any]] else{
                        return
                    }
                    
                    var foundDate = false
                    
                    //This string will be formed from all of the opening times,
                    //allowing us to format it depending on if there are 0,1, or more
                    //opening times available
                    var openingTimesFinalString = ""
                    
                    //Loop through the times for all dates, and find the ones that match today's date.
                    for dh in dateHoursArray{
                        guard let date = dh["date"] as? String else{
                            return
                        }
                        
                        //Get the current date and format it to match the json format
                        let currentDate = Date()
                        let format = DateFormatter()
                        format.dateFormat = "yyyy-MM-dd"
                        let currentDateFormatted = format.string(from: currentDate)
                        var openingTimes = [String]()
                        
                        //We have found the opening times for today's date
                        if(currentDateFormatted == date){
                            
                            foundDate = true
                            guard let meal = dh["meal"] as? [[String: Any]] else{
                                return
                            }
                            
                            for m in meal{
                                
                                //Get the information we need about the particular venue
                                guard let openTimes = m["open"] as? String else{
                                    return
                                }
                                guard let closeTimes = m["close"] as? String else{
                                    return
                                }
                                guard let typeOfMeal = m["type"] as? String else{
                                    return
                                }
                                
                                //Ignore the time if the place is closed at that time.
                                if(typeOfMeal == "Closed"){continue}
                                
                                //Format the times appropriately
                                //This is some cumbersome code but manipulating strings in Swift
                                //changes all the time and it is a pain :/
                                let ch = Array(openTimes)
                                var chNew = [Character]()
                                //Don't display first 0 (e.g 09:30 becomes 9:30)
                                if(ch[0] != "0"){
                                    chNew.append(ch[0])
                                }
                                chNew.append(ch[1])
                                //Don't display minutes if 0 minutes (e.g 09:00 becomes 9)
                                if(ch[3] != "0" && ch[4] != "0"){
                                    chNew.append(ch[2])
                                    chNew.append(ch[3])
                                    chNew.append(ch[4])
                                }
                                
                                //Repeat same formatting for closing time
                                let ch2 = Array(closeTimes)
                                var ch2New = [Character]()
                                //Don't display first 0 (e.g 09:30 becomes 9:30)
                                if(ch2[0] != "0"){
                                    ch2New.append(ch2[0])
                                }
                                ch2New.append(ch2[1])
                                //Don't display minutes if 0 minutes (e.g 09:00 becomes 9)
                                if(ch2[3] != "0" && ch2[4] != "0"){
                                    ch2New.append(ch2[2])
                                    ch2New.append(ch2[3])
                                    ch2New.append(ch2[4])
                                }
                                
                                let openingTimeFormatted = String(chNew)
                                let closingTimeFormatted = String(ch2New)
                                openingTimes.append(openingTimeFormatted + " - " + closingTimeFormatted)
                            }
                            
                        }
                        
                        
                        //Only 1 time, so format time like "8a-9p"
                        //NOT FULLY IMPLEMENTED
                        if(openingTimes.count == 1){
                            openingTimesFinalString = openingTimes[0];
                        }
                            //More than 1 time, so format time like "12 - 3 | 3 - 5"
                        else{
                            for (i,o) in openingTimes.enumerated(){
                                //Join times into one string, and don't add bar (|) after last time
                                openingTimesFinalString += o + " " + ((i == openingTimes.count - 1) ? "" : "|")
                            }
                        }
                        
                    }
                    //No times found, so the place is closed today
                    if(!foundDate){
                        openingTimesFinalString = ("CLOSED TODAY")
                    }
                    
                    //Create the venue object and add it to the correct array to be updated
                    let v = Venue(name: name, imageUrl: imageURL, openingHours: openingTimesFinalString, venueType: venueType, facilityUrl: facilityUrl)
                    if(venueType == "residential"){
                        residentialVenues.append(v)
                    }
                    else if(venueType == "retail"){
                        retailVenues.append(v)
                    }
                    
                }
                print("Data obtained")
                
                //Update the class variables asynchronously
                DispatchQueue.main.async {
                    self.residentialVenues = residentialVenues
                    self.retailVenues = retailVenues
                }
                
            } catch let parsingError {
                print("Error", parsingError)
            }
            
        }
        
        task.resume()
    }
    
}

//Webview struct taken from https://forums.developer.apple.com/thread/117348
struct WebView : UIViewRepresentable {
    
    let request: URLRequest
    
    func makeUIView(context: Context) -> WKWebView  {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(request)
    }
    
}

let greyishTwo = Color(white: 164.0/255.0)

//Get a formatted string for the current date
func getDate() -> String{
    let date = Date()
    let formatter = DateFormatter()
    //This is the required format for displaying the date
    //Example: Sunday, July 14
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: date)
}

//This is a container to store the information we need about each location
struct Venue{
    var name: String;
    var imageUrl: String;
    var openingHours: String;
    var venueType: String;
    var facilityUrl: String;
}

//We use this to share the showWebPage bool and the url between views
class ShowWebpageManager: ObservableObject {
    @Published var showWebpage = false
    @Published var url = ""
}

//This is the view for each dining venue/hall displayed in the app, makes the code much neater
struct HallView: View {
    
    //Venue object is needed here to obtain the information to display, like the image url, venue name, etc.
    let hall: Venue
    
    //Variable we defined in the ShowWebpageManager class, shared with ContentView to notify it to open the webpage for this dining venue.
    @EnvironmentObject var webpageManager: ShowWebpageManager
    
    var body: some View{
        Button(action: {
            self.webpageManager.url = self.hall.facilityUrl
            self.webpageManager.showWebpage = true;
        }) {
            HStack{
                //To dispaly images from a url, I am using this library I found online that provides this URLImage view.
                //Link to github: https://github.com/dmytro-anokhin/url-image
                URLImage(URL(string: hall.imageUrl)!).resizable().renderingMode(.original)
                    .frame(width: 120.0, height: 80.0).cornerRadius(7)
                //Vertical stack containing the information about whether the place is open, its name and its times.
                VStack(alignment: .leading){
                    //UNIMPLEMENTED: Indicating whether venue is open currently (app will always say it is open as of right now)
                    Text("OPEN").font(.body).bold().foregroundColor(Color.blue)
                    Text(hall.name)
                        .font(.headline).foregroundColor(Color.black)
                    
                    //Get the list of opening times
                    Text(hall.openingHours).foregroundColor(Color.black)
                }.frame(width: 220, height: 80, alignment: .leading)
                
                //Little arrow that makes the button more clear
                VStack(alignment: .leading){
                    Image(systemName: "arrow.right")
                }
            }
        }.foregroundColor(Color.black)
    }
}
struct ContentView: View {
    
    //This object is used to update the view with the infromation we fetch from the API like the images and opening times
    @ObservedObject var networkManager = NetworkManager()
    //Obtain the current date to display on the top of the app
    @State private var currentDate = getDate()
    //Object that contains a bool to indicate whether to show a dining venue's webpage, and the link to that webpage
    @EnvironmentObject var webpageManager: ShowWebpageManager
    
    var body: some View {
        return Group{
            //Display the webpage for a particular dining hall if it has been tapped.
            if(self.webpageManager.showWebpage){
                NavigationView{
                    WebView(request: URLRequest(url: URL(string: self.webpageManager.url)!))
                        .navigationBarTitle("More information")
                        .navigationBarItems(leading:
                            Button(action: {
                                self.webpageManager.showWebpage = false
                            }) {
                                Text("Back")
                        })
                }
            }
            //Otherwise, display the main part of the app
            else{
                ScrollView(showsIndicators: false){
                    VStack(alignment: .leading){
                        Text("\(currentDate)")
                            .kerning(-0.27)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(greyishTwo)
                        
                        //Dining Halls heading
                        Text("Dining Halls")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        //Build a HallView for each residential dining hall
                        ForEach(networkManager.residentialVenues, id: \.name) {hall in
                            HallView(hall: hall)
                        }
                        
                        //Retail dining heading
                        Text("Retail Dining")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        //Build a HallView for each retail venue
                        ForEach(networkManager.retailVenues, id: \.name) {hall in
                            HallView(hall: hall)
                        }
                    }.padding(.leading, 0)
                }
            }
            
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
