function Load-Token {
    param (
        [string]$TokenValue = $env:OPENAI_API_KEY  # Defaulting to retrieve from an environment variable
    )

    if (-not $global:apiToken) {
        # Check if the token value provided is not empty
        if (-not $TokenValue) {
            $TokenValue = Read-Host -Prompt "Please enter your OpenAI API Key"
            if (-not $TokenValue) {
                Write-Error "Token was not provided."
                return
            }
        }

        $global:apiToken = $TokenValue
    }
}

function Calculate-Cost {
    param (
        [int]$InputTokens,
        [int]$OutputTokens,
        [string]$Model
    )

    $inputCost = 0
    $outputCost = 0

    switch ($Model) {
        "gpt-4" {
            $inputCost = ($InputTokens / 1000) * 0.03
            $outputCost = ($OutputTokens / 1000) * 0.06
        }
        "gpt-4-32k" {
            $inputCost = ($InputTokens / 1000) * 0.06
            $outputCost = ($OutputTokens / 1000) * 0.12
        }
        "gpt-3.5-turbo" {
            $inputCost = ($InputTokens / 1000) * 0.0015
            $outputCost = ($OutputTokens / 1000) * 0.002
        }
        "gpt-3.5-turbo-16k" {
            $inputCost = ($InputTokens / 1000) * 0.003
            $outputCost = ($OutputTokens / 1000) * 0.004
        }
        default {
            Write-Error "Invalid or unsupported model: $Model"
            return 0
        }
    }

    return ($inputCost + $outputCost)
}

function Get-DecimalFormat {
    param (
        [double]$Value
    )

    if ($Value -lt 0.0001) {
        return "{0:N6}" # Six decimal places
    } elseif ($Value -lt 0.001) {
        return "{0:N5}" # Five decimal places
    } else {
        return "{0:N4}" # Default to four decimal places
    }
}

function ask-chatgpt {
    param (
        [string]$UserInput,
        [string]$SystemInput = $null,
        [ValidateSet("gpt-3.5-turbo", "gpt-3.5-turbo-16k", "gpt-4", "gpt-4-16k")]
        [string]$Model = "gpt-3.5-turbo",
        [double]$Temperature = 0,
        [int]$MaxTokens = 1024,
        [double]$TopP = 1,
        [double]$FrequencyPenalty = 0,
        [double]$PresencePenalty = 0,
        [switch]$ResetConversation,
        [switch]$ShowCost,
        [switch]$ConversationMode,
        [switch]$ColorCode,
        [switch]$ShowFullHistory
    )

    # Ensure the token is loaded
    Load-Token

    # Exit if the token is not set
    if (-not $global:apiToken) {
        Write-Error "API token is not set."
        return
    }

    # Reset conversation history if the switch is set
    if ($ResetConversation) {
        $script:conversationHistory = @()
    }

    if ($ConversationMode) {
        Write-Host "Entering conversation mode. Type 'exit' to end the conversation."
        do {
            # Prompt the user for input inside the loop, ignoring the function's original $UserInput
            $UserInput = Read-Host "You"

            # If the user types "exit", break out of the loop
            if ($UserInput -ieq "exit") {
                break
            }

            # Call the chat API with the user's input and continue with the same conversation
            $responseContent = & ask-chatgpt -UserInput $UserInput -ShowCost:$ShowCost

            Write-Host ("ChatGPT: " + $responseContent)
        } while ($true)
        return
    }

    # Endpoint for the ChatGPT API
    $uri = "https://api.openai.com/v1/chat/completions"

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $global:apiToken"
    }

    # If SystemInput is provided, prepend it to the conversation history
    if ($SystemInput) {
        $script:conversationHistory = @(@{ role = "system"; content = $SystemInput }) + $script:conversationHistory
    }

    # Keep the conversation history in a script-level variable
    $script:conversationHistory += @(@{ role = "user"; content = $UserInput })

    if ($ShowFullHistory){
        $script:conversationHistory
    }

    $Body = @{
        model = $Model
        messages = $script:conversationHistory
        temperature = $Temperature
        max_tokens = $MaxTokens
        top_p = $TopP
        frequency_penalty = $FrequencyPenalty
        presence_penalty = $PresencePenalty
    }

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($Body | ConvertTo-Json)

        # Add the assistant's response to the conversation history
        $script:conversationHistory += @(@{ role = "assistant"; content = $response.choices[0].message.content })

        # If ShowCost switch is set, display token usage and cost
        if ($ShowCost) {
            $promptTokens = $response.usage.prompt_tokens
            $completionTokens = $response.usage.completion_tokens

            $cost = Calculate-Cost -InputTokens $promptTokens -OutputTokens $completionTokens -Model $Model
            $formatString = Get-DecimalFormat -Value $cost

            Write-Host "Prompt token usage (Input): " -NoNewline
            Write-Host $promptTokens -ForegroundColor Green
            Write-Host "Completion token usage (Output): " -NoNewline
            Write-Host $completionTokens -ForegroundColor Red
            Write-Host "Total token usage: " -NoNewline  
            Write-Host ($promptTokens + $completionTokens) -ForegroundColor DarkYellow
            Write-Host "Estimated cost: " -NoNewline
            Write-Host ($formatString -f $cost) -ForegroundColor Yellow
        }

        # Return only the message content
        if ($ColorCode){
            $split = $response.choices[0].message.content -split '```'
            $count = 0
            foreach ($item in $split){
            $count++
            $item = $item.Trim()
            if ($count % 2 -eq 1){
                write-host $item
                }else{
                write-host $item -ForegroundColor Red
                }
            }
        }else{
            return $response.choices[0].message.content
        }
    } catch {
        Write-Error "Failed to query the ChatGPT API. Error: $_"
    }
}
