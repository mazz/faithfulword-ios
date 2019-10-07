import Foundation

public struct UserSignupResponse: Codable {
    public var token: String
    public var user: UserLoginUser
}
/*
 {
 "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJmYWl0aGZ1bF93b3JkX3Byb2QiLCJleHAiOjE1NjgwNjQzNzYsImlhdCI6MTU2NTQ3MjM3NiwiaXNzIjoiRmFpdGhmdWxXb3JkIiwianRpIjoiZjY0Y2Y2ODItYjE0Mi00M2E4LTliOTQtMTMyMDUwMTRjNDJkIiwibmJmIjoxNTY1NDcyMzc1LCJzdWIiOiJVc2VyOjMiLCJ0eXAiOiJhY2Nlc3MifQ.WuqRvVzqnd2o9Rjlyd5hwmgLSicnt9g96EaEl5fvRzAnuqPBz2ycVLx6aVVXJR1N0R5aYLko2JxXCf0xRdZYIw",
 "user": {
 "achievements": [
 1
 ],
 "email": "joseph@faithfulword.app",
 "fb_user_id": null,
 "id": 3,
 "is_publisher": true,
 "locale": null,
 "mini_picture_url": "https://api.adorable.io/avatars/24/3.png",
 "name": null,
 "picture_url": "https://api.adorable.io/avatars/96/3.png",
 "registered_at": "2019-06-22T14:17:10Z",
 "reputation": 4200,
 "username": "Joseph"
 }
 }
 
 
 */
