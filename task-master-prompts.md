# Task Master AI Prompts Documentation

This document catalogs the AI prompts used throughout the Task Master system. Each section documents a specific prompt, its purpose, implementation details, and how it's used in the codebase.

## Table of Contents

1. [Parse PRD Prompt](#parse-prd-prompt)
2. [Expand Task Prompt](#expand-task-prompt)
3. [Analyze Task Complexity Prompt](#analyze-task-complexity-prompt)
4. [Update Task Prompt](#update-task-prompt)
5. [Update Multiple Tasks Prompt](#update-multiple-tasks-prompt)
6. [Update Subtask Prompt](#update-subtask-prompt)
7. [Add Task Prompt](#add-task-prompt)
8. [Additional Prompts](#additional-prompts)

## Parse PRD Prompt

**Purpose**: Parses a Product Requirements Document (PRD) and generates a structured list of development tasks in JSON format.

**Location**: `scripts/modules/task-manager/parse-prd.js`

**Usage**:
- Called by the `parse-prd` command and MCP tool
- Converts a text-based PRD into structured tasks with IDs, dependencies, and implementation details
- Generates approximately the requested number of tasks, adapting to PRD complexity 
- Maintains dependency ordering and assigns appropriate priorities
- Ensures tasks adhere to technical requirements specified in the PRD

### System Prompt

```
You are an AI assistant specialized in analyzing Product Requirements Documents (PRDs) and generating a structured, logically ordered, dependency-aware and sequenced list of development tasks in JSON format.
Analyze the provided PRD content and generate approximately ${numTasks} top-level development tasks. If the complexity or the level of detail of the PRD is high, generate more tasks relative to the complexity of the PRD
Each task should represent a logical unit of work needed to implement the requirements and focus on the most direct and effective way to implement the requirements without unnecessary complexity or overengineering. Include pseudo-code, implementation details, and test strategy for each task. Find the most up to date information to implement each task.
Assign sequential IDs starting from ${nextId}. Infer title, description, details, and test strategy for each task based *only* on the PRD content.
Set status to 'pending', dependencies to an empty array [], and priority to 'medium' initially for all tasks.
Respond ONLY with a valid JSON object containing a single key "tasks", where the value is an array of task objects adhering to the provided Zod schema. Do not include any explanation or markdown formatting.

Each task should follow this JSON structure:
{
	"id": number,
	"title": string,
	"description": string,
	"status": "pending",
	"dependencies": number[] (IDs of tasks this depends on),
	"priority": "high" | "medium" | "low",
	"details": string (implementation details),
	"testStrategy": string (validation approach)
}

Guidelines:
1. Unless complexity warrants otherwise, create exactly ${numTasks} tasks, numbered sequentially starting from ${nextId}
2. Each task should be atomic and focused on a single responsibility following the most up to date best practices and standards
3. Order tasks logically - consider dependencies and implementation sequence
4. Early tasks should focus on setup, core functionality first, then advanced features
5. Include clear validation/testing approach for each task
6. Set appropriate dependency IDs (a task can only depend on tasks with lower IDs, potentially including existing tasks with IDs less than ${nextId} if applicable)
7. Assign priority (high/medium/low) based on criticality and dependency order
8. Include detailed implementation guidance in the "details" field
9. If the PRD contains specific requirements for libraries, database schemas, frameworks, tech stacks, or any other implementation details, STRICTLY ADHERE to these requirements in your task breakdown and do not discard them under any circumstance
10. Focus on filling in any gaps left by the PRD or areas that aren't fully specified, while preserving all explicit requirements
11. Always aim to provide the most direct path to implementation, avoiding over-engineering or roundabout approaches
```

### User Prompt

```
Here's the Product Requirements Document (PRD) to break down into approximately ${numTasks} tasks, starting IDs from ${nextId}:

${prdContent}

Return your response in this format:
{
    "tasks": [
        {
            "id": 1,
            "title": "Setup Project Repository",
            "description": "...",
            ...
        },
        ...
    ],
    "metadata": {
        "projectName": "PRD Implementation",
        "totalTasks": ${numTasks},
        "sourceFile": "${prdPath}",
        "generatedAt": "YYYY-MM-DD"
    }
}
```

### Implementation Details

The prompts include several variable placeholders:
- `${numTasks}`: The desired number of tasks to generate
- `${nextId}`: The starting ID for task numbering (important for append operations)
- `${prdContent}`: The actual content of the PRD document
- `${prdPath}`: The file path of the PRD, used in metadata

The AI's response is validated against a Zod schema that ensures the returned data has the correct structure:
- A `tasks` array containing task objects with required fields
- Each task has proper ID, title, description, status, etc.
- Optional metadata for the project

The system handles various scenarios:
- Appending new tasks to existing ones
- Overwriting existing tasks (with the `--force` flag)
- Generating tasks from scratch
- Handling dependencies between new and existing tasks

After the AI generates the tasks, the system:
1. Assigns proper sequential IDs
2. Validates and remaps dependencies
3. Writes the tasks to the tasks.json file
4. Generates individual markdown task files

## Expand Task Prompt

**Purpose**: Breaks down a high-level task into more detailed, actionable subtasks with implementation guidance.

**Location**: `scripts/modules/task-manager/expand-task.js`

**Usage**:
- Called by the `expand` command and MCP tool
- Allows developers to decompose complex tasks into manageable subtasks
- Creates dependency chains between subtasks to establish order
- Provides specific implementation details for each subtask
- Can incorporate complexity analysis to determine the appropriate level of detail

### System Prompt (Standard)

```
You are an AI assistant helping with task breakdown for software development.
You need to break down a high-level task into ${subtaskCount} specific subtasks that can be implemented one by one.

Subtasks should:
1. Be specific and actionable implementation steps
2. Follow a logical sequence
3. Each handle a distinct part of the parent task
4. Include clear guidance on implementation approach
5. Have appropriate dependency chains between subtasks (using the new sequential IDs)
6. Collectively cover all aspects of the parent task

For each subtask, provide:
- id: Sequential integer starting from the provided nextSubtaskId
- title: Clear, specific title
- description: Detailed description
- dependencies: Array of prerequisite subtask IDs (use the new sequential IDs)
- details: Implementation details
- testStrategy: Optional testing approach


Respond ONLY with a valid JSON object containing a single key "subtasks" whose value is an array matching the structure described. Do not include any explanatory text, markdown formatting, or code block markers.
```

### User Prompt (Standard)

```
Break down this task into exactly ${subtaskCount} specific subtasks:

Task ID: ${task.id}
Title: ${task.title}
Description: ${task.description}
Current details: ${task.details || 'None'}
${contextPrompt}

Return ONLY the JSON object containing the "subtasks" array, matching this structure:
{
  "subtasks": [
    {
      "id": ${nextSubtaskId}, // First subtask ID
      "title": "Specific subtask title",
      "description": "Detailed description",
      "dependencies": [], // e.g., [${nextSubtaskId + 1}] if it depends on the next
      "details": "Implementation guidance",
      "testStrategy": "Optional testing approach"
    },
    // ... (repeat for a total of ${subtaskCount} subtasks with sequential IDs)
  ]
}
```

### User Prompt (Research Mode)

```
Analyze the following task and break it down into exactly ${subtaskCount} specific subtasks using your research capabilities. Assign sequential IDs starting from ${nextSubtaskId}.

Parent Task:
ID: ${task.id}
Title: ${task.title}
Description: ${task.description}
Current details: ${task.details || 'None'}
${contextPrompt}

CRITICAL: Respond ONLY with a valid JSON object containing a single key "subtasks". The value must be an array of the generated subtasks, strictly matching this structure:
{
  "subtasks": [
    {
      "id": <number>, // Sequential ID starting from ${nextSubtaskId}
      "title": "<string>",
      "description": "<string>",
      "dependencies": [<number>], // e.g., [${nextSubtaskId + 1}]. If no dependencies, use an empty array [].
      "details": "<string>",
      "testStrategy": "<string>" // Optional
    },
    // ... (repeat for ${subtaskCount} subtasks)
  ]
}

Important: For the 'dependencies' field, if a subtask has no dependencies, you MUST use an empty array, for example: "dependencies": []. Do not use null or omit the field.

Do not include ANY explanatory text, markdown, or code block markers. Just the JSON object.
```

### Implementation Details

The expand task functionality uses two different prompt approaches:

1. **Standard Mode**: Uses the main AI provider (typically Claude) to break down tasks based on the provided information in the task itself.

2. **Research Mode**: Uses a research-capable AI provider (typically Perplexity) that can incorporate outside knowledge to create more informed subtasks.

The prompts include several variable placeholders:
- `${subtaskCount}`: Number of subtasks to generate (determined from explicit input, complexity analysis, or default configuration)
- `${task.id/title/description/details}`: Information about the parent task
- `${nextSubtaskId}`: Starting ID number for subtasks (typically 1 for new breakdowns)
- `${contextPrompt}`: Optional additional context provided by the user

The system integrates with complexity analysis:
- If a complexity report exists for the project, the system will use it to determine the appropriate number of subtasks
- Task complexity scores (1-10) help determine the appropriate granularity (more subtasks for higher complexity)
- The complexity report's reasoning is included in the prompt when available

After the AI generates the subtasks, the system:
1. Validates each subtask using a Zod schema
2. Ensures proper ID sequencing and dependency relationships
3. Updates the parent task with the new subtasks
4. Updates the tasks.json file
5. Regenerates the individual task files

## Analyze Task Complexity Prompt

**Purpose**: Analyzes the complexity of tasks and provides recommendations for breaking them down into subtasks.

**Location**: `scripts/modules/task-manager/analyze-task-complexity.js`

**Usage**:
- Called by the `analyze-complexity` command and MCP tool
- Assesses each task's complexity on a scale of 1-10
- Recommends the appropriate number of subtasks based on complexity
- Provides reasoning for the complexity assessment
- Generates an initial expansion prompt tailored to each task

### System Prompt

```
You are an expert software architect and project manager analyzing task complexity. Respond only with the requested valid JSON array.
```

### User Prompt

```
Analyze the following tasks to determine their complexity (1-10 scale) and recommend the number of subtasks for expansion. Provide a brief reasoning and an initial expansion prompt for each.

Tasks:
${tasksString}

Respond ONLY with a valid JSON array matching the schema:
[
  {
    "taskId": <number>,
    "taskTitle": "<string>",
    "complexityScore": <number 1-10>,
    "recommendedSubtasks": <number>,
    "expansionPrompt": "<string>",
    "reasoning": "<string>"
  },
  ...
]

Do not include any explanatory text, markdown formatting, or code block markers before or after the JSON array.
```

### Implementation Details

The complexity analysis prompt processes active tasks (those not marked as done, cancelled, or deferred) from the task list and provides a structured analysis of each:

- `tasksString`: A JSON representation of the active tasks in the project
- `complexityScore`: A rating from 1-10 indicating implementation complexity (higher is more complex)
- `recommendedSubtasks`: Suggested number of subtasks to break the task into
- `expansionPrompt`: Initial context/prompt to use when expanding this task
- `reasoning`: Explanation of why the task received its complexity score

The system can operate in two modes:
1. **Standard mode**: Uses the main AI provider to analyze tasks
2. **Research mode**: Uses a research-capable AI provider that may have access to up-to-date technical information

The output is saved as a JSON report which is then used by:
- The `complexity-report` command to display a human-readable version of the analysis
- The `expand-task` command to determine the appropriate number of subtasks when breaking down a task
- The `expand-all` command to efficiently expand multiple tasks according to their complexity

After analyzing tasks, the system provides a summary showing:
- Number of high/medium/low complexity tasks
- Tasks that need immediate attention (complexity score ≥ threshold, default 5)
- Expansion recommendations for each task

## Update Task Prompt

**Purpose**: Updates an existing task's details based on new information or changes.

**Location**: `scripts/modules/task-manager/update-task-by-id.js`

**Usage**:
- Called by the `update-task` command and MCP tool
- Modifies a task's description, details, and test strategy based on new context
- Keeps completed subtasks unchanged while adding new subtasks as needed
- Handles changes to implementation approach without losing track of work already done
- Maintains the task structure while incorporating new information

### System Prompt

```
You are an AI assistant helping to update a software development task based on new context.
You will be given a task and a prompt describing changes or new implementation details.
Your job is to update the task to reflect these changes, while preserving its basic structure.

Guidelines:
1. VERY IMPORTANT: NEVER change the title of the task - keep it exactly as is
2. Maintain the same ID, status, and dependencies unless specifically mentioned in the prompt
3. Update the description, details, and test strategy to reflect the new information
4. Do not change anything unnecessarily - just adapt what needs to change based on the prompt
5. Return a complete valid JSON object representing the updated task
6. VERY IMPORTANT: Preserve all subtasks marked as "done" or "completed" - do not modify their content
7. For tasks with completed subtasks, build upon what has already been done rather than rewriting everything
8. If an existing completed subtask needs to be changed/undone based on the new context, DO NOT modify it directly
9. Instead, add a new subtask that clearly indicates what needs to be changed or replaced
10. Use the existence of completed subtasks as an opportunity to make new subtasks more specific and targeted
11. Ensure any new subtasks have unique IDs that don't conflict with existing ones

The changes described in the prompt should be thoughtfully applied to make the task more accurate and actionable.
```

### User Prompt

```
Here is the task to update:
${taskDataString}

Please update this task based on the following new context:
${prompt}

IMPORTANT: In the task JSON above, any subtasks with "status": "done" or "status": "completed" should be preserved exactly as is. Build your changes around these completed items.

Return only the updated task as a valid JSON object.
```

### Implementation Details

The update task functionality intelligently updates existing tasks based on new information:

- `${taskDataString}`: A JSON representation of the current task to be updated
- `${prompt}`: The user-provided text describing the changes to be made

The system includes several safeguards to protect task integrity:
- The task title is preserved to maintain consistency
- Completed subtasks are never modified to maintain work history
- The task ID and dependencies remain unchanged unless specifically mentioned
- Only necessary changes are made based on the prompt content

After the AI generates the updated task:
1. The system validates the response against a schema
2. It ensures proper ID preservation
3. It preserves completed subtasks exactly as they were
4. It updates the tasks.json file
5. It regenerates the individual task files

## Update Multiple Tasks Prompt

**Purpose**: Updates multiple tasks at once based on new information or implementation changes.

**Location**: `scripts/modules/task-manager/update-tasks.js`

**Usage**:
- Called by the `update` command and MCP tool
- Updates all non-completed tasks with IDs greater than or equal to a specified ID
- Applies the same changes across multiple related tasks
- Useful for implementing architectural shifts or dependency updates
- Maintains the integrity of completed subtasks while updating future work

### System Prompt

```
You are an AI assistant helping to update software development tasks based on new context.
You will be given a set of tasks and a prompt describing changes or new implementation details.
Your job is to update the tasks to reflect these changes, while preserving their basic structure.

Guidelines:
1. Maintain the same IDs, statuses, and dependencies unless specifically mentioned in the prompt
2. Update titles, descriptions, details, and test strategies to reflect the new information
3. Do not change anything unnecessarily - just adapt what needs to change based on the prompt
4. You should return ALL the tasks in order, not just the modified ones
5. Return a complete valid JSON object with the updated tasks array
6. VERY IMPORTANT: Preserve all subtasks marked as "done" or "completed" - do not modify their content
7. For tasks with completed subtasks, build upon what has already been done rather than rewriting everything
8. If an existing completed subtask needs to be changed/undone based on the new context, DO NOT modify it directly
9. Instead, add a new subtask that clearly indicates what needs to be changed or replaced
10. Use the existence of completed subtasks as an opportunity to make new subtasks more specific and targeted

The changes described in the prompt should be applied to ALL tasks in the list.
```

### User Prompt

```
Here are the tasks to update:
${taskDataString}

Please update these tasks based on the following new context:
${prompt}

IMPORTANT: In the tasks JSON above, any subtasks with "status": "done" or "status": "completed" should be preserved exactly as is. Build your changes around these completed items.

Return only the updated tasks as a valid JSON array.
```

### Implementation Details

The update multiple tasks functionality applies changes across a range of tasks:

- `${taskDataString}`: A JSON representation of all tasks to be updated
- `${prompt}`: The user-provided text describing the changes to be made

The system carefully maintains various aspects of the task structure:
- Task IDs and dependencies remain unchanged
- Task statuses are preserved unless explicitly mentioned
- Completed subtasks remain untouched
- Only necessary changes are made based on the prompt

This functionality is especially useful when there's a significant change in approach that affects multiple tasks, such as:
- Changing the tech stack or framework
- Updating data storage or authentication methods
- Shifting the architecture pattern
- Replacing a library or dependency

After the AI generates the updated tasks:
1. The system validates the response format
2. It checks that the correct number of tasks was returned
3. It applies the updates to the original task structure
4. It updates the tasks.json file
5. It regenerates the individual task files

## Update Subtask Prompt

**Purpose**: Appends new information to a subtask's details based on user input.

**Location**: `scripts/modules/task-manager/update-subtask-by-id.js`

**Usage**:
- Called by the `update-subtask` command and MCP tool
- Adds timestamped information to an existing subtask's details
- Preserves existing details while appending new content
- Useful for logging implementation progress or adding notes
- Provides context from parent tasks and sibling subtasks for continuity

### System Prompt

```
You are an AI assistant helping to update a subtask. You will be provided with the subtask's existing details, context about its parent and sibling tasks, and a user request string.

Your Goal: Based *only* on the user's request and all the provided context (including existing details if relevant to the request), GENERATE the new text content that should be added to the subtask's details.
Focus *only* on generating the substance of the update.

Output Requirements:
1. Return *only* the newly generated text content as a plain string. Do NOT return a JSON object or any other structured data.
2. Your string response should NOT include any of the subtask's original details, unless the user's request explicitly asks to rephrase, summarize, or directly modify existing text.
3. Do NOT include any timestamps, XML-like tags, markdown, or any other special formatting in your string response.
4. Ensure the generated text is concise yet complete for the update based on the user request. Avoid conversational fillers or explanations about what you are doing (e.g., do not start with "Okay, here's the update...").
```

### User Prompt

```
Task Context:
${contextString}

User Request: "${prompt}"

Based on the User Request and all the Task Context (including current subtask details provided above), what is the new information or text that should be appended to this subtask's details? Return ONLY this new text as a plain string.
```

### Implementation Details

The update subtask functionality appends new information to subtask details:

- `${contextString}`: Information about the parent task and adjacent subtasks for context
- `${prompt}`: The user-provided text describing what should be added to the subtask

The system focuses on generating only the new content to be appended, not modifying existing content. This creates a log of progressive updates to the subtask as implementation proceeds.

Key aspects of the implementation:
- The AI returns only the new text to append, not the entire subtask details
- The system wraps the new content in timestamp tags to track when each update was made
- Original content is preserved with new content appended at the end
- The system can operate in research mode for more informed updates
- Context includes information about the parent task and adjacent subtasks

The timestamped approach creates a development journal within each subtask, showing the progression of implementation over time.

## Add Task Prompt

**Purpose**: Creates a new task based on a description.

**Location**: `scripts/modules/task-manager/add-task.js`

**Usage**:
- Called by the `add-task` command and MCP tool
- Generates a well-structured task from a brief description
- Creates implementation details and test strategy for the task
- Assigns appropriate dependencies and priority as specified
- Integrates with the existing task structure

### System Prompt

```
You are a helpful assistant that creates well-structured tasks for a software development project. Generate a single new task based on the user's description, adhering strictly to the provided JSON schema.
```

### User Prompt

```
Create a comprehensive new task (Task #${newTaskId}) for a software development project based on this description: "${prompt}"
      
${contextTasks}
${contextFromArgs ? `\nConsider these additional details provided by the user:${contextFromArgs}` : ''}
      
Return your answer as a single JSON object matching the schema precisely:
{
  "title": "Task title goes here",
  "description": "A concise one or two sentence description of what the task involves",
  "details": "In-depth implementation details, considerations, and guidance.",
  "testStrategy": "Detailed approach for verifying task completion."
}
      
Make sure the details and test strategy are thorough and specific.
```

### Implementation Details

The add task functionality creates new tasks based on user descriptions:

- `${newTaskId}`: The ID to be assigned to the new task
- `${prompt}`: The user-provided description of the task to create
- `${contextTasks}`: Information about existing tasks for context (if any)
- `${contextFromArgs}`: Any additional details provided through command arguments

The system generates a complete task with:
- A clear, concise title
- A brief description summarizing the task's purpose
- Detailed implementation guidance in the "details" field
- A specific testing approach in the "testStrategy" field

The task is validated against a schema and then added to the tasks.json file with:
- The assigned ID
- The specified dependencies (if any)
- The specified priority (or default "medium")
- A "pending" status
- An empty subtasks array

The resulting task can then be expanded into subtasks using the expand-task command.

## Additional Prompts

This document provides a comprehensive list of all AI prompts used in the Task Master codebase. After a thorough examination of the codebase, we've confirmed that all instances of `generateTextService`, `generateObjectService`, and `streamTextService` AI function calls have been documented above.

The `initialize_project` command/tool was also examined and does not use AI prompts as it focuses on setting up the file structure and configuration rather than generating content. 