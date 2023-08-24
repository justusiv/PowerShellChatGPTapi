# PowerShellChatGPTapi
# Always read and understand code before you run it on your system!!

Switching
-ShowCost
-ResetConversation
-ConversationMode
-ColorCode
-ShowFullHistory

# Example usage:
Load-Token -TokenValue "apikey"

ask-chatgpt -UserInput "what is zero kelvin" -ShowCost -ResetConversation
![image](https://github.com/justusiv/PowerShellChatGPTapi/assets/1114622/6cce1bc1-e01b-4803-b569-dabb1666edf3)

ask-chatgpt "what is 2+2" -ResetConversation
![image](https://github.com/justusiv/PowerShellChatGPTapi/assets/1114622/c583f1e5-16a0-4b48-a9f3-25292de94147)

ask-chatgpt -ConversationMode -ResetConversation
![image](https://github.com/justusiv/PowerShellChatGPTapi/assets/1114622/2b71f082-0ca4-4f39-8363-557abf22d2ba)

ask-chatgpt -ResetConversation -ColorCode -SystemInput "You write clean well documented code" -UserInput "give me a powershell function that gets the total size of a directory as a parameter" 
![image](https://github.com/justusiv/PowerShellChatGPTapi/assets/1114622/82fc6d39-2f1f-4b8e-ac9c-e390ae16f7ac)

ask-chatgpt -ResetConversation "what is 2+2"
ask-chatgpt "what if you replace the 2s with 3s"
![image](https://github.com/justusiv/PowerShellChatGPTapi/assets/1114622/1fced40d-5ecc-4cfc-ac28-87ff3091bdc3)
