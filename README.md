# Penn-Labs-Challenge
Submission for the Penn Labs technical challenge, consisting of an iOS app made with SwiftUI to display the Penn dining options.

## Introduction
Welcome! This is my submission for the Penn Labs technical challenge. For this project, I chose to use the brand new SwiftUI user interface toolkit, and the Combine framework (also brand-new!). This was my first contact with SwiftUI and it wasn't easy to learn (the syntax is very, very weird), but I thought that it would be a fun challenge!

## How it was built
This app was made using SwiftUI for creating the user interface and Combine for reactive elements (asynchronous image and text loading).

### Structure

#### Main Screen
When the app is opened, the main screen is shown. It is built using a `ScrollView`, which contains a `VStack`. Inside the `VStack`, `Text` views are used to display any headings. Then, each row of dining venue is built using a `HallView` - a custom view built by myself to contain the image and information for each hall.

#### Displaying a Dining Venue's menu
Whenever a `HallView` is clicked, the 'ScrollView' disappears and is replaced by a `Navigation` view, which contains a `WebView` (wrapped thanks to Bradley Hilton over at https://forums.developer.apple.com/thread/117348) which contains the webpage with the dining venue's menu.

### Asynchronous loading
The JSON data is downloaded from the API through the `NetworkManager` class. This class makes use of Combine to serve as an ObservableObject. This allows us to asynchronously fetch the JSON data, format it and create `HallView` views for each dining venue. Thanks to Combine, as soon as the data is received and processed the views are automatically updated to display the obtained information.

## Built With

* [URLImage](https://github.com/dmytro-anokhin/url-image) - Used to download the images given a URL

## Authors

* Henrique Lorente (UPenn SEAS 2023)
