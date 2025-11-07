# Admin Zone Editing Feature

## Overview
This feature allows admin players to create and remove rooms and doors in real-time while playing the game using a special "Admin Stick" item. The feature includes commands for creating/deleting rooms and doors with appropriate prompts and confirmations.

## The Magic Admin Stick

The Admin Stick is a special legendary item that grants zone editing powers to administrators. When an admin character is created or logs in, the system automatically grants them the Admin Stick if they don't already have it.

### Admin Stick Properties
- Name: "Admin Zone Editing Stick"
- Description: "A magical stick that allows admins to modify zones"
- Item type: "tool"
- Rarity: "legendary"
- Equippable: false
- Stackable: false
- Cannot be dropped or destroyed by players

## In-Game Room and Door Editing

Admins can modify the game world in real-time by using specific commands while wielding the Admin Stick. All editing commands follow a simple pattern and provide immediate feedback.

### Available Commands

1. `create room <direction>` - Creates a new room in the specified direction
2. `delete room <direction>` - Deletes the room in the specified direction
3. `create door <direction>` - Creates a door to an existing adjacent room
4. `delete door <direction>` - Deletes the door in the specified direction

### Supported Directions
- Cardinal directions: north, south, east, west
- Diagonal directions: northeast, northwest, southeast, southwest
- Short forms: n, s, e, w, ne, nw, se, sw

### Usage Instructions

#### Creating a Room
1. Ensure you're in a valid room (not in empty space)
2. Type: `create room [direction]` (e.g., `create room north`)
3. The system will:
   - Verify you have the Admin Stick
   - Calculate coordinates in the specified direction
   - Check that no room already exists there
   - Create a new room with a coordinate-based name
   - Automatically create a door connecting your current room to the new room
   - Create a return door in the opposite direction

#### Deleting a Room
1. Ensure you're in a valid room
2. Type: `delete room [direction]` (e.g., `delete room south`)
3. The system will:
   - Verify you have the Admin Stick
   - Check if a room exists in that direction
   - Delete the room and all doors connected to it
   - Note: Any players or items in the deleted room will need to be handled separately

#### Creating a Door
1. Ensure you're in a valid room
2. Type: `create door [direction]` (e.g., `create door east`)
3. The system will:
   - Verify you have the Admin Stick
   - Check if a room exists in that direction
   - Verify no door already exists in that direction
   - Create a door to the adjacent room
   - Create a return door in the opposite direction

#### Deleting a Door
1. Ensure you're in a valid room
2. Type: `delete door [direction]` (e.g., `delete door west`)
3. The system will:
   - Verify you have the Admin Stick
   - Check if a door exists in that direction
   - Delete the door and its corresponding return door

### Room Properties

When a room is created, it automatically gets the following properties:
- Name: "Room (X, Y)" where X and Y are the coordinates
- Description: "A newly created room at coordinates (X, Y)."
- Room Type: "standard"
- Public: true
- Properties: Empty map (%{})
- Z-coordinate: 0 (all rooms are on the ground floor by default)

### Door Properties

When a door is created, it automatically gets the following properties:
- Direction: The specified direction
- Door Type: "standard"
- Locked: false
- Return door is automatically created in the opposite direction

## Functions Needed

### 1. Item Creation Functions
- `create_admin_stick_item()`: Creates the special Admin Stick item in the database
- `grant_admin_stick_to_admins()`: Automatically gives the Admin Stick to admin characters when they spawn

### 2. Command Parsing Functions
- `parse_create_room_command(direction)`: Parses "create room <direction>" command
- `parse_delete_room_command(direction)`: Parses "delete room <direction>" command
- `parse_create_door_command(direction)`: Parses "create door <direction>" command
- `parse_delete_door_command(direction)`: Parses "delete door <direction>" command

### 3. Room Management Functions
- `prompt_for_room_description(direction)`: Prompts admin for room description
- `create_new_room(zone_id, coordinates, description)`: Creates a new room in the database
- `confirm_delete_room(room_id)`: Shows confirmation prompt for room deletion
- `delete_existing_room(room_id)`: Deletes a room from the database

### 4. Door Management Functions
- `prompt_for_door_description(direction)`: Prompts admin for door description
- `create_new_door(from_room_id, to_room_id, direction)`: Creates a new door in the database
- `confirm_delete_door(door_id)`: Shows confirmation prompt for door deletion
- `delete_existing_door(door_id)`: Deletes a door from the database

### 5. Permission Functions
- `has_admin_stick(character_id)`: Checks if character has Admin Stick in inventory
- `is_authorized_admin(character_id)`: Verifies if character is an admin user

### 6. UI/UX Functions
- `show_admin_prompt(message)`: Displays prompts to the admin player
- `show_admin_confirmation(message)`: Displays confirmation dialogs
- `show_admin_success(message)`: Shows success messages
- `show_admin_error(message)`: Shows error messages

## Implementation Steps

### Step 1: Create the Admin Stick Item
1. Add a new item type in the database for the Admin Stick
2. Set properties:
   - Name: "Admin Zone Editing Stick"
   - Description: "A magical stick that allows admins to modify zones"
   - Item type: "tool"
   - Rarity: "legendary"
   - Equippable: false
   - Stackable: false

### Step 2: Implement Item Granting System
1. Modify character spawning logic to check if user is admin
2. If admin, automatically add Admin Stick to their inventory
3. Ensure the stick cannot be dropped or destroyed

### Step 3: Add Command Parsers
1. Extend command parsing system to recognize new commands:
   - "create room <direction>"
   - "delete room <direction>"
   - "create door <direction>"
   - "delete door <direction>"
2. Validate command syntax and parameters

### Step 4: Implement Room Creation Workflow
1. When "create room <direction>" is issued:
   - Check if player has Admin Stick
   - Check if player is in a valid zone
   - Calculate coordinates based on direction
   - Check if room already exists at those coordinates
   - Prompt for room description
   - Create room in database
   - Create door from current room to new room
   - Create return door from new room to current room

### Step 5: Implement Room Deletion Workflow
1. When "delete room <direction>" is issued:
   - Check if player has Admin Stick
   - Find room in specified direction
   - Show confirmation prompt
   - If confirmed, delete room and all associated doors
   - Handle any characters in the room being deleted

### Step 6: Implement Door Creation Workflow
1. When "create door <direction>" is issued:
   - Check if player has Admin Stick
   - Check if door already exists in that direction
   - Prompt for door description
   - Create door in database
   - Create return door in opposite direction

### Step 7: Implement Door Deletion Workflow
1. When "delete door <direction>" is issued:
   - Check if player has Admin Stick
   - Find door in specified direction
   - Show confirmation prompt
   - If confirmed, delete door and return door

### Step 8: Add Permission Checks
1. Implement authorization functions to verify:
   - Character has Admin Stick equipped/in inventory
   - Character's user account has admin privileges
   - Character is in a zone they're allowed to modify

### Step 9: Create UI/UX Components
1. Implement prompt systems for:
   - Room descriptions
   - Door descriptions
   - Confirmation dialogs
   - Success/error messages

### Step 10: Add Error Handling
1. Handle edge cases:
   - Invalid directions
   - Rooms/doors that don't exist
   - Rooms/doors that already exist
   - Database errors
   - Insufficient permissions

### Step 11: Testing
1. Test all commands in various scenarios
2. Verify permission systems work correctly
3. Test edge cases and error conditions
4. Verify database integrity after modifications

### Step 12: Documentation
1. Update user documentation with new commands
2. Create admin documentation for the feature
3. Add technical documentation for maintenance
