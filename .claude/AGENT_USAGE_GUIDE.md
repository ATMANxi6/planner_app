# Flutter Agent System - Usage Guide

## Overview

Your Life Planner project now has four specialized agents accessible via slash commands. These agents help you work on different aspects of Flutter development with focused expertise.

## Available Agents

### 🔌 `/backend` - Backend Agent
**Focus**: API Integration, Data Management, Local Storage

Use this agent when you need to:
- Implement API calls and network communication
- Work with Hive models and local storage
- Handle data serialization/deserialization
- Implement repository patterns
- Manage error handling for network operations
- Set up caching strategies

**Example usage**:
```
/backend I need to add a new field to the Task model for tracking time spent
/backend Help me implement offline sync for the tasks
/backend Create a repository for fetching user profile data
```

### 🎨 `/frontend` - Frontend Agent
**Focus**: UI/UX, Widgets, Visual Design

Use this agent when you need to:
- Build or modify widget trees
- Implement responsive layouts
- Create custom reusable widgets
- Handle animations and transitions
- Improve user experience
- Work with theming and design systems

**Example usage**:
```
/frontend Create a new widget for displaying streak information
/frontend Make the dashboard more responsive on tablets
/frontend Add a smooth animation when tasks are completed
/frontend Improve the visual hierarchy of the planner screen
```

### 🧠 `/logic` - Logic Agent
**Focus**: Business Logic, State Management, Architecture

Use this agent when you need to:
- Implement business rules and validations
- Work with Provider state management
- Design feature architecture
- Handle complex workflows
- Coordinate between UI and data layers
- Implement use cases and application services

**Example usage**:
```
/logic Add validation to prevent scheduling overlapping time blocks
/logic Refactor the task completion logic to handle subtask dependencies
/logic Design the state management for a new goal tracking feature
/logic Implement business rules for streak calculations
```

### 🎯 `/coordinate` - Multi-Agent Coordinator
**Focus**: Complex Features Requiring Multiple Agents

Use this agent when you need to:
- Build complete features that span UI, logic, and data
- Coordinate work across multiple layers
- Plan large architectural changes
- Get guidance on which agent to use
- Understand the collaboration workflow

**Example usage**:
```
/coordinate I want to add a new feature for habit tracking with reminders
/coordinate Help me refactor the project visualization system
/coordinate Plan the architecture for adding cloud sync
```

## When to Use Each Agent

### Decision Matrix

| Task | Agent | Why |
|------|-------|-----|
| Add new Hive field | `/backend` | Data model changes |
| Create dashboard widget | `/frontend` | UI component |
| Add validation rule | `/logic` | Business logic |
| Build new feature | `/coordinate` | Multi-layer coordination |
| Style existing widget | `/frontend` | Visual design |
| Fix API error handling | `/backend` | Network layer |
| Refactor Provider | `/logic` | State management |
| Optimize widget rebuild | `/frontend` | Performance/UI |
| Add task dependency check | `/logic` | Business rules |
| Implement local caching | `/backend` | Data persistence |

## Workflow Examples

### Example 1: Simple Widget Change
```
You: /frontend Add a FAB to the dashboard for quick task creation
Agent: [Focuses on UI implementation, widget composition, UX]
```

### Example 2: Business Logic Change
```
You: /logic Update the recurring task reset logic to handle custom frequencies
Agent: [Focuses on business rules, validation, state management]
```

### Example 3: Complex Feature
```
You: /coordinate I want to add time tracking to tasks with start/stop timers
Agent: [Coordinates all three agents to handle UI, logic, and data layers]
  → Backend: Add TimeEntry model, storage service
  → Logic: Implement timer state management, calculation rules
  → Frontend: Create timer UI widget, display time summaries
```

## Best Practices

### 1. Start Specific
Use the specialized agent (`/backend`, `/frontend`, `/logic`) when you know exactly what layer you're working on.

### 2. Use Coordinator for Planning
Use `/coordinate` when you're unsure which agent to use or when the task spans multiple layers.

### 3. Context Matters
The agents understand your Life Planner project structure from `CLAUDE.md`, so they'll follow your existing patterns.

### 4. Combine Agents
For complex features, you can use agents sequentially:
1. `/coordinate` - Plan the feature
2. `/backend` - Implement data layer
3. `/logic` - Add business logic
4. `/frontend` - Build UI

### 5. Ask for Guidance
All agents can explain their decisions and suggest alternatives. Don't hesitate to ask "why" or "what's the best approach."

## Agent Capabilities

Each agent:
- ✅ Understands your Life Planner codebase structure
- ✅ Follows Flutter and Dart best practices
- ✅ Works with your existing Hive models and Providers
- ✅ Respects your architectural patterns (Provider, ChangeNotifier)
- ✅ Can explain their reasoning and trade-offs
- ✅ Provides code examples that fit your project

## Tips for Effective Use

### Be Clear About Scope
Good: "Add a completed date field to the Task model"
Better: "Add a completedAt DateTime field to the Task model and update TaskProvider to set it when marking tasks complete"

### Provide Context When Needed
"I'm working on the burndown chart and need to calculate remaining time estimates across all subtasks in a project"

### Ask for Explanations
"Why did you choose to put this logic in the Provider instead of the widget?"

### Request Alternatives
"What are the pros and cons of using a stream vs a future for this?"

## Troubleshooting

### Command Not Found?
Make sure you're typing the slash command correctly:
- `/backend` ✅
- `/Backend` ❌ (case-sensitive)
- `backend` ❌ (needs the `/`)

### Agent Seems Off-Topic?
The agent might not have enough context. Try:
1. Being more specific about your task
2. Mentioning which file or feature you're working on
3. Using `/coordinate` to get guidance on which agent is best

### Need to Switch Agents?
You can invoke a different agent at any time in the conversation. The context from your previous messages will still be available.

## Project-Specific Context

Your Life Planner app has:
- **Three task types**: distractions, practices, goals
- **Hive storage** with specific boxes (tasks, projects, mindMap, timeBlocks)
- **Provider state management** with TaskProvider, ProjectProvider, etc.
- **Visualization tools**: Gantt charts, Kanban boards, burndown charts
- **Time blocking**: Daily and weekly calendar views

All agents understand this context and will work within your established patterns.

## Getting Help

If you're ever unsure:
1. Use `/coordinate` to get guidance
2. Ask "Which agent should I use for X?"
3. Review the agent role descriptions in their markdown files

---

Happy coding! Your specialized agents are ready to help you build an amazing Life Planner app. 🚀
