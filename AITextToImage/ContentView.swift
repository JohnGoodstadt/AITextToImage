//
//  ContentView.swift
//  AITextToImage
//
//  Created by John goodstadt on 23/11/2023.
//

import SwiftUI

private let apiKey = "Your API Key Here"
private let urlString = "https://api.openai.com/v1/images/generations"

struct ContentView: View {
	@State private var selectedBuiltInQuestion = true
	@State private var selectedQuestion: String = ""
	@State var hideActivityIndicator: Bool = true
	@State var phrase:String = ""
	
	@State private var selectedAnswer = ""
	@State private var fullResponse = ""
	@State private var fullRequest = ""
	@State private var isResponseButtonDisabled = true
	@State private var isGetImageButtonDisabled = true
	@State private var showingRequestSheet = false
	@State private var showingResponseSheet = false
	@State private var dalleUrl = ""
	@State private var selectedSize   = "256x256"
	@FocusState private var inFocus: Bool
	
	
	@State var uiImage: UIImage?
	
	var questionTitles = ["A Serene Mountain Village in Autumn",
						  "A Futuristic City at Night",
						  "An Underwater Coral Reef Scene with Diverse Marine Life:"]
	
	var questionDetails = ["A Serene Mountain Village in Autumn: Envision a picturesque mountain village during autumn. The village is nestled in a valley with rolling hills, surrounded by majestic mountains with peaks lightly dusted in snow. The scene is bathed in the warm, golden light of a setting sun. Trees in vibrant shades of red, orange, and yellow dot the landscape, and a small, tranquil river winds through the village. Traditional wooden cottages with smoking chimneys and thatched roofs are scattered around, and villagers are seen enjoying the evening, some walking dogs, others sitting on porches.",
						   "A Futuristic City at Night: Imagine a bustling, futuristic cityscape at night, illuminated by neon lights. Skyscrapers of varying and imaginative shapes tower above, with glowing windows and holographic billboards. Flying cars and hoverbikes zip through the air, leaving trails of light behind them. Pedestrians walk on transparent skywalks connecting buildings. In the foreground, there's a lively market with vendors selling exotic, otherworldly goods and food, with people of diverse appearances, some even in futuristic attire, exploring the stalls.",
						   "An Underwater Coral Reef Scene with Diverse Marine Life: Picture a vibrant underwater coral reef, teeming with life. The reef is a kaleidoscope of colors with corals of all shapes and sizes, surrounded by clear blue water that filters light in beautiful patterns. Schools of colorful fish swim around, including clownfish, angelfish, and neon tetras. A curious sea turtle gently swims by, while a small group of dolphins can be seen in the distance. In a more secluded part of the reef, a hidden octopus camouflages itself among the corals, and a gentle manta ray glides overhead."]
	
	
	init(){
		selectedQuestion = questionTitles.first!
	}
	
	var body: some View {
		VStack {
			
			Text("A cute baby sea otter")
				.padding()
			
			VStack (alignment: .trailing){
				Button(action: {
					selectedBuiltInQuestion = true
					inFocus = false
				}) {
					HStack  {
						Image(systemName: selectedBuiltInQuestion ? "largecircle.fill.circle" : "circle")
							.foregroundColor(.blue)
						Text("Choose this description")
						Spacer()
					}
				}
			}//: VSTACK
			
			Picker("Select a description", selection: $selectedQuestion) {
				ForEach(questionTitles, id: \.self) {
					Text($0).tag($0)
						.onTapGesture {
							selectedBuiltInQuestion = true
							inFocus = false
						}
				}
			}//: PICKER
			.pickerStyle(.menu)
			.padding([.top,.bottom],16)
			
			VStack (alignment: .leading){
				Button(action: {
					selectedBuiltInQuestion = false
					inFocus = false
				}) {
					HStack  {
						Image(systemName: !selectedBuiltInQuestion ? "largecircle.fill.circle" : "circle")
							.foregroundColor(.blue)
						Text("Choose my description")
						Spacer()
					}
				}
			}//: VSTACK
			
			ZStack(alignment: .leading) {
				
				
				TextEditor( text: $phrase)  //.id(0)
					.font(.custom("Helvetica", size: 16))
					.padding(.all)
					.focused($inFocus,equals: true)
					.frame(height: 100)
					.onChange(of: phrase, perform: { value in
						if selectedBuiltInQuestion {
							selectedBuiltInQuestion = false
						}
					})
					.onTapGesture {
						selectedBuiltInQuestion = false
					}
				
				
			}//: ZSTACK
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(.gray, lineWidth: 0.6)
			)
			
			Picker("Size:",selection: $selectedSize) {
				Text("256x256").tag("256x256").font(.title3)
				Text("512x512").tag("512x512").font(.title3)
				Text("1024x1024").tag("1024x1024").font(.title3)
			}
			.pickerStyle(SegmentedPickerStyle())
			.padding(.top,4)
			.padding(.bottom,4)
			.onChange(of: selectedSize) {	tag in
				print(tag)
				selectedSize =  tag
			}
			
			HStack{
				Button(action: {
					
					if !selectedBuiltInQuestion && phrase.isEmpty {
						//selectedAnswer = "Enter some text before calling openAI"
					}else{
						inFocus = false
						hideActivityIndicator = false
						//					selectedAnswer = ""
						//					fullResponse = ""
						
						//					let engine = selectedEngineType
						
						var text = phrase
						if selectedBuiltInQuestion {
							if selectedQuestion.isEmpty {
								selectedQuestion = questionTitles.first!
							}
							//get full question
							text = getFullDescription(selectedQuestion)
						}
						print(text)
						
						callOpenAI(text: text,size: selectedSize)
					}
					
				}) {
					Text("Call DALL-E")
						.padding()
				}.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(.blue, lineWidth: 0.6)
				)
				Spacer()
				ActivityIndicatorView(tintColor: .red, scaleSize: 2.0)
					.padding([.bottom,.top],16)
					.hidden(hideActivityIndicator)
				
				
				Spacer()
				Button(action: {
					showingRequestSheet.toggle()
					inFocus = false
					
				}) {
					Text("request")
						.font(.subheadline)
						.padding()
						.disabled(isResponseButtonDisabled)
				}.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(.blue, lineWidth: 0.6)
				)
				.sheet(isPresented: $showingRequestSheet) {
					FullRequestView(requestMessage: fullRequest)
				}
				
				Spacer()
				
				Button(action: {
					showingResponseSheet.toggle()
					inFocus = false
				}) {
					Text("response")
						.font(.subheadline)
						.padding()
						.disabled(isResponseButtonDisabled)
				}.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(.blue, lineWidth: 0.6)
				)
				.sheet(isPresented: $showingResponseSheet) {
					FullResponseView(responseMessage: fullResponse)
				}
			}//:HStack
			HStack {
				Button(action: {
					inFocus = false
					
					callGetImage(imageURL: dalleUrl)
					
				}) {
					Text("Get image")
						.padding(8)
						.font(.footnote)
						.disabled(isGetImageButtonDisabled)
						.disabled(false)
				}.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(.blue, lineWidth: 0.6)
				)
				Text("\(String(dalleUrl.prefix(40)))")
					.padding(8)
					.font(.footnote)
					.disabled(isGetImageButtonDisabled)
				Spacer()
			}//: HSTACK
			
			Spacer()
			
			if let uiImage = self.uiImage {
				Image(uiImage: uiImage)
					.resizable()
			} else {
				Image(systemName: "photo")
					.resizable()
					.imageScale(.large)
					.foregroundStyle(.tint)
					.aspectRatio(contentMode: .fit)
				
			}
			
		} //: VSTACK
		.padding()
	}//: BODY
	struct ActivityIndicatorView: View {
		var tintColor: Color = .blue
		var scaleSize: CGFloat = 1.0
		
		var body: some View {
			ProgressView()
				.scaleEffect(scaleSize, anchor: .center)
				.progressViewStyle(CircularProgressViewStyle(tint: tintColor))
		}
	}
	func callOpenAI(text:String,size:String){
		
		isGetImageButtonDisabled = true
		isResponseButtonDisabled = true
		
		if let url = URL(string: urlString) {
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
			
			let body: [String: Any] = ["prompt": text,"n": 1, "size": size]
			print(body)
			
			do {
				// Convert the parameters to JSON data
				let jsonData = try JSONSerialization.data(withJSONObject: body)
				request.httpBody = jsonData
				fullRequest = "\(body)"
				fullRequest = request.debug()
				
				URLSession.shared.dataTask(with: request) { (data, response, error) in
					if let error = error {
						print("Error: \(error.localizedDescription)")
						fullResponse = error.localizedDescription
						selectedAnswer = error.localizedDescription
						isResponseButtonDisabled = false //can be timeout error
						hideActivityIndicator = true
						return
					}
					
					if let data = data {
						// Parse and handle the response data here
						// Typically, this will involve extracting the generated text
						hideActivityIndicator = true
						let chatOutput = String(decoding: data, as: UTF8.self)
						fullResponse = chatOutput
						do {
							if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
								// Access the data you need from the JSON response
								if let choices = json["data"] as? [[String: Any]], !data.isEmpty {
									
									print(choices)
									if let urlDict = choices.first, let url = urlDict["url"] as? String {
										print("Generated Image url: \(url)")
										selectedAnswer = url
										dalleUrl = String(url)
										isGetImageButtonDisabled = false
									}
									
								}
							}
						} catch {
							print("Error parsing JSON: \(error.localizedDescription)")
						}
						isResponseButtonDisabled = false
					}
				}.resume()
			} catch {
				print("Error converting parameters to JSON: \(error.localizedDescription)")
			}
		}
		
	}
	func callGetImage(imageURL:String){
		
		if let url = URL(string: imageURL) {
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let error = error {
					print("Error: \(error.localizedDescription)")
					fullResponse = error.localizedDescription
					selectedAnswer = error.localizedDescription
					isResponseButtonDisabled = false //can be timeout error
					hideActivityIndicator = true
					return
				}
				
				if let data = data {
					hideActivityIndicator = true
					fullResponse = String( response.debugDescription)
					let uiImage = UIImage(data: data)
					
					DispatchQueue.main.async {
						self.uiImage = uiImage
					}
					
					isResponseButtonDisabled = false
				}
			}.resume()
		}
	}
	fileprivate func getFullDescription(_ shortDescription:String) -> String {
		
		if let i = questionTitles.firstIndex(of:shortDescription) {
			return questionDetails[i]
		}
		
		return shortDescription
	}
}

fileprivate extension View {
	@ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
		switch shouldHide {
			case true: self.hidden()
			case false: self
		}
	}
}
fileprivate extension URLRequest {
	func debug() -> String {
		
		var returnValue = "\n\(self.httpMethod!) \(self.url!) "
		returnValue += "\n\nHeaders:\n"
		returnValue += "\(String(describing: self.allHTTPHeaderFields))"
		returnValue += "\n\nBody:\n"
		returnValue += String(data: self.httpBody ?? Data(), encoding: .utf8) ?? "default value"
		
		return returnValue
	}
}
#Preview {
	ContentView()
}
