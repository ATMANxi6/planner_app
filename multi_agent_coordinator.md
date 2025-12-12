# Flutter Multi-Agent System Coordinator

## Overview
This document outlines how the three specialized Flutter agents work together to deliver optimal results for your Flutter development projects.

## Agent Roles Summary

### 🎨 Frontend Agent
**Focus**: UI/UX, Widgets, Visual Design
**Strength**: Creating beautiful, responsive interfaces

### 🔌 Backend Agent
**Focus**: API Integration, Data Management, Storage
**Strength**: Connecting to services and managing data flow

### 🧠 Logic Agent
**Focus**: Business Logic, State Management, Architecture
**Strength**: Coordinating features and enforcing rules

## Collaboration Workflow

### Scenario 1: Building a New Feature (e.g., User Profile)

#### Phase 1: Requirements & Architecture
**Logic Agent leads:**
1. Defines the use cases (GetUser, UpdateUser)
2. Specifies business rules (validation, permissions)
3. Chooses state management approach (BLoC pattern)
4. Defines entities and state objects

**Output to others:**
- UserState definitions
- Required repository methods
- Validation requirements

#### Phase 2: Data Layer Implementation
**Backend Agent leads:**
1. Creates User model with JSON serialization
2. Implements UserRepository with API calls
3. Sets up local caching strategy
4. Handles error mapping

**Output to others:**
- User data model structure
- Available repository methods
- Error types that can occur

#### Phase 3: UI Implementation
**Frontend Agent leads:**
1. Creates ProfileScreen widget
2. Connects to UserBloc from Logic Agent
3. Displays user data from Backend models
4. Handles loading/error states

**Coordination points:**
- Uses state objects defined by Logic Agent
- Displays data models from Backend Agent
- Triggers events back to Logic Agent

### Scenario 2: Handling User Input (e.g., Form Submission)

**Flow:**
```
[User Input] → Frontend Agent
              ↓
         Logic Agent (validates)
              ↓
         Backend Agent (saves)
              ↓
         Logic Agent (updates state)
              ↓
         Frontend Agent (shows result)
```

**Frontend Agent:**
- Captures user input
- Triggers form submission event
- Displays validation errors
- Shows success/error feedback

**Logic Agent:**
- Receives form data
- Applies business validation rules
- Coordinates save operation
- Manages loading/success/error states

**Backend Agent:**
- Receives validated data
- Makes API call
- Handles network errors
- Returns result to Logic Agent

## Communication Protocol

### Request Format
When agents need information from each other:

```markdown
**To: [Agent Name]**
**From: [Agent Name]**
**Request**: [What you need]
**Context**: [Why you need it]
**Priority**: [High/Medium/Low]
```

### Response Format
```markdown
**Agent**: [Agent Name]
**Response to**: [Original request]
**Deliverable**: [What you're providing]
**Dependencies**: [What this depends on]
**Next Steps**: [What should happen next]
```

## Decision Matrix

| Decision Type | Primary Agent | Consulted Agents |
|--------------|---------------|------------------|
| UI Layout | Frontend | Logic (for state), Backend (for data shape) |
| State Management | Logic | Frontend (for UI needs), Backend (for data needs) |
| API Structure | Backend | Logic (for business rules), Frontend (for UI needs) |
| Validation Rules | Logic | Frontend (for UX), Backend (for API constraints) |
| Navigation Flow | Logic | Frontend (for UX), Backend (for data availability) |
| Error Handling | Backend | Logic (for user-facing messages), Frontend (for display) |
| Performance Optimization | All | Coordinate based on bottleneck location |

## Example: Complete Feature Implementation

### Feature: Shopping Cart

#### Step 1: Logic Agent defines architecture
```dart
// Use cases
- AddItemToCart
- RemoveItemFromCart
- UpdateItemQuantity
- ClearCart
- CheckoutCart

// Business rules
- Maximum 10 items per product
- Cart expires after 24 hours
- Calculate total with tax
- Apply discount codes
```
/fron
#### Step 2: Backend Agent implements data layer
```dart
// Models
- CartItem
- Cart
- Product

// Repository methods
- getCart()
- saveCart()
- clearCart()

// API endpoints
- POST /cart/items
- DELETE /cart/items/:id
- PUT /cart/items/:id
```

#### Step 3: Frontend Agent creates UI
```dart
// Screens
- CartScreen
- CartItemWidget
- CheckoutButton

// Displays
- Item list with quantities
- Total calculation
- Empty cart state
- Loading indicators
```

#### Step 4: Integration
- Frontend dispatches `AddItemToCart` event
- Logic validates business rules
- Backend saves to local storage and API
- Logic updates state
- Frontend rebuilds with new state

## Conflict Resolution

### When agents disagree:

1. **Performance vs Features**
   - Logic Agent mediates
   - Consider user impact
   - Implement feature flags if needed

2. **UI vs Data Structure**
   - Backend Agent provides data as-is
   - Logic Agent transforms if needed
   - Frontend adapts to transformed data

3. **Architecture Decisions**
   - Logic Agent has final say on patterns
   - Must justify with maintainability/testability
   - Document decisions for team

## Best Practices for Multi-Agent Workflow

### 1. Start with Logic Agent
Always begin feature development by having Logic Agent define:
- Use cases and business rules
- State management approach
- Data flow architecture

### 2. Parallel Development
After architecture is defined:
- Backend can work on data layer
- Frontend can create UI mockups
- Logic can implement business logic

### 3. Integration Points
Define clear contracts:
```dart
// Logic defines state
abstract class CartState {}

// Backend defines models
class CartModel {}

// Frontend uses both
class CartScreen extends StatelessWidget {
  // Uses CartState from Logic
  // Displays CartModel from Backend
}
```

### 4. Testing Strategy
- **Frontend**: Widget tests
- **Backend**: Integration tests for API
- **Logic**: Unit tests for business rules
- **All**: End-to-end tests for critical flows

## Communication Examples

### Example 1: Frontend needs data structure
```markdown
**To: Backend Agent**
**From: Frontend Agent**
**Request**: User profile data structure
**Context**: Building profile screen, need to know what fields are available
**Priority**: High

**Backend Response**:
UserModel includes:
- id: String
- name: String
- email: String
- avatarUrl: String?
- bio: String?
- createdAt: DateTime

Available through UserRepository.getUser(userId)
```

### Example 2: Backend needs validation rules
```markdown
**To: Logic Agent**
**From: Backend Agent**
**Request**: Validation rules for user registration
**Context**: Need to validate data before sending to API
**Priority**: High

**Logic Response**:
- Email: Must be valid format, required
- Password: Min 8 chars, must include number and special char
- Name: Required, min 2 chars, max 50 chars
- Age: Must be 13 or older

Validator classes provided in domain/validators/
```

## Anti-Patterns to Avoid

❌ **Don't**: Have Frontend directly call API services
✅ **Do**: Go through Logic layer (use cases/BLoCs)

❌ **Don't**: Put business logic in widgets
✅ **Do**: Keep widgets purely presentational

❌ **Don't**: Let Backend Agent make UI decisions
✅ **Do**: Backend provides data, Frontend decides presentation

❌ **Don't**: Duplicate logic across layers
✅ **Do**: Centralize in Logic Agent, share through interfaces

## Success Metrics

Your multi-agent system is working well when:
- ✅ Each agent stays within their domain
- ✅ Communication is clear and documented
- ✅ Dependencies are well-defined
- ✅ Code is testable in isolation
- ✅ Changes in one layer don't cascade unnecessarily
- ✅ All agents agree on data contracts

## Quick Reference

### Who handles what?

| Task | Agent | Reasoning |
|------|-------|-----------|
| Widget composition | Frontend | Visual presentation |
| API calls | Backend | Data access |
| Form validation | Logic | Business rules |
| State management | Logic | Application flow |
| Error display | Frontend | User experience |
| Error handling | Backend | Data layer concerns |
| Navigation | Logic | App flow control |
| Animations | Frontend | Visual effects |
| Caching | Backend | Data optimization |
| Feature flags | Logic | Business decisions |

---

## Getting Started with Your Agents

1. **Initialize Project Architecture**
   - Start with Logic Agent to define structure
   - Set up dependency injection
   - Choose state management solution

2. **Implement Core Features**
   - Work on one feature at a time
   - Follow the 3-phase workflow
   - Maintain clear communication

3. **Iterate and Improve**
   - Review code with all agents
   - Refactor for clarity
   - Document decisions

4. **Scale Your System**
   - Add new features using same pattern
   - Keep agents focused on their domains
   - Maintain clean architecture principles
