// =============================================================================
// VALE DESIGN SUITE - 2D CANVAS NAVIGATION SYSTEM
// =============================================================================
//
// FILE       : 2dCanvasNavigation.js
// PURPOSE    : Canvas navigation, zoom, pan, and viewport management
// AUTHOR     : Generated for Vale Design Suite
// CREATED    : 2025
//
// DESCRIPTION:
// - Provides zoom, pan, and navigation controls for the hatch canvas
// - Implements mouse wheel zoom, drag pan, and keyboard navigation
// - Maintains viewport state and provides smooth transitions
// - Integrates with existing canvas rendering system
//
// =============================================================================

// -----------------------------------------------------------------------------
// REGION | Module Variables and State Management
// -----------------------------------------------------------------------------

    // MODULE VARIABLES | Canvas Navigation State Variables
    // ------------------------------------------------------------
    let canvasNavigationState = {
        isPanning                    : false,                                  // <-- Flag for pan mode
        isZooming                    : false,                                  // <-- Flag for zoom mode
        lastMouseX                   : 0,                                      // <-- Last mouse X position
        lastMouseY                   : 0,                                      // <-- Last mouse Y position
        viewportX                    : 0,                                      // <-- Current viewport X offset
        viewportY                    : 0,                                      // <-- Current viewport Y offset
        zoomLevel                    : 1.0,                                    // <-- Current zoom level
        minZoom                      : 0.1,                                    // <-- Minimum zoom level
        maxZoom                      : 10.0,                                   // <-- Maximum zoom level
        zoomStep                     : 0.1,                                    // <-- Zoom increment per wheel step
        panSpeed                     : 1.0,                                    // <-- Pan movement speed multiplier
        zoomCenterX                  : 0,                                      // <-- Zoom center X coordinate
        zoomCenterY                  : 0,                                      // <-- Zoom center Y coordinate
        canvasWidth                  : 0,                                      // <-- Canvas width in pixels
        canvasHeight                 : 0,                                      // <-- Canvas height in pixels
        contentBounds                : { minX: 0, minY: 0, maxX: 0, maxY: 0 }, // <-- Content bounding box
        animationFrameId             : null,                                   // <-- Animation frame ID for smooth transitions
        isInitialized                : false                                   // <-- Initialization flag
    };
    // ------------------------------------------------------------

    // MODULE VARIABLES | Canvas Element References
    // ------------------------------------------------------------
    let canvasElement                = null;                                   // <-- Canvas DOM element reference
    let canvasContext                = null;                                   // <-- Canvas 2D context reference
    let canvasContainer              = null;                                   // <-- Canvas container element
    // ------------------------------------------------------------

    // MODULE VARIABLES | Navigation Control Elements
    // ------------------------------------------------------------
    let navigationControls           = null;                                   // <-- Navigation controls container
    let zoomInButton                 = null;                                   // <-- Zoom in button element
    let zoomOutButton                = null;                                   // <-- Zoom out button element
    let resetViewButton              = null;                                   // <-- Reset view button element
    let fitToScreenButton            = null;                                   // <-- Fit to screen button element
    let panModeButton                = null;                                   // <-- Pan mode toggle button
    let spacebarHeld                 = false;                                  // <-- Track spacebar state for temporary pan
    // ------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Canvas Navigation Initialization
// -----------------------------------------------------------------------------

    // FUNCTION | Initialize Canvas Navigation System
    // ------------------------------------------------------------
    function initializeCanvasNavigation() {
        if (canvasNavigationState.isInitialized) return;                       // <-- Prevent double initialization
        
        try {
            setupCanvasReferences();                                           // <-- Get canvas element references
            setupNavigationControls();                                         // <-- Create navigation UI controls
            setupEventListeners();                                             // <-- Bind event listeners
            setupCanvasResizeObserver();                                       // <-- Monitor canvas size changes
            resetViewportToDefault();                                          // <-- Set initial viewport state
            
            canvasNavigationState.isInitialized = true;                        // <-- Mark as initialized
            console.log('Canvas Navigation System initialized successfully');   // <-- Log initialization success
        } catch (error) {
            console.error('Failed to initialize Canvas Navigation:', error);   // <-- Log initialization errors
        }
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Canvas Element References
    // ---------------------------------------------------------------
    function setupCanvasReferences() {
        canvasElement = document.getElementById('hatch-canvas');                // <-- Get canvas element
        canvasContainer = document.getElementById('canvas-container');          // <-- Get container element
        
        if (!canvasElement || !canvasContainer) {                              // <-- Validate elements exist
            throw new Error('Canvas elements not found');
        }
        
        canvasContext = canvasElement.getContext('2d');                        // <-- Get 2D context
        updateCanvasDimensions();                                              // <-- Set initial dimensions
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Navigation Controls UI
    // ---------------------------------------------------------------
    function setupNavigationControls() {
        createNavigationControlsHTML();                                        // <-- Create navigation UI
        setupControlButtonReferences();                                        // <-- Get button references
        setupControlButtonEventListeners();                                    // <-- Bind button events
        updateNavigationControlStates();                                       // <-- Set initial button states
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Create Navigation Controls HTML
    // ---------------------------------------------------------------
    function createNavigationControlsHTML() {
        const controlsHTML = `
            <div id="canvas-navigation-controls" class="canvas-navigation-controls">
                <div class="navigation-button-group">
                    <button id="zoom-in-btn" class="nav-button" title="Zoom In (Ctrl + +)">
                        <span class="nav-icon">+</span>
                    </button>
                    <button id="zoom-out-btn" class="nav-button" title="Zoom Out (Ctrl + -)">
                        <span class="nav-icon">−</span>
                    </button>
                    <button id="reset-view-btn" class="nav-button" title="Reset View (Ctrl + 0)">
                        <span class="nav-icon">⌂</span>
                    </button>
                    <button id="fit-screen-btn" class="nav-button" title="Fit to Screen (Ctrl + F)">
                        <span class="nav-icon">⤢</span>
                    </button>
                </div>
                <div class="navigation-info">
                    <span id="zoom-level-display">100%</span>
                    <span id="pan-mode-indicator" class="pan-mode-indicator">Pan Mode: Off</span>
                </div>
            </div>
        `;
        
        canvasContainer.insertAdjacentHTML('beforeend', controlsHTML);         // <-- Add controls to container
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Control Button References
    // ---------------------------------------------------------------
    function setupControlButtonReferences() {
        navigationControls = document.getElementById('canvas-navigation-controls'); // <-- Get controls container
        zoomInButton = document.getElementById('zoom-in-btn');                 // <-- Get zoom in button
        zoomOutButton = document.getElementById('zoom-out-btn');                // <-- Get zoom out button
        resetViewButton = document.getElementById('reset-view-btn');            // <-- Get reset view button
        fitToScreenButton = document.getElementById('fit-screen-btn');          // <-- Get fit to screen button
        panModeButton = document.getElementById('pan-mode-btn');                // <-- Get pan mode button (if exists)
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Control Button Event Listeners
    // ---------------------------------------------------------------
    function setupControlButtonEventListeners() {
        zoomInButton.addEventListener('click', () => zoomIn());                 // <-- Zoom in on click
        zoomOutButton.addEventListener('click', () => zoomOut());               // <-- Zoom out on click
        resetViewButton.addEventListener('click', () => resetView());           // <-- Reset view on click
        fitToScreenButton.addEventListener('click', () => fitToScreen());       // <-- Fit to screen on click
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Event Listeners and Interaction Handling
// -----------------------------------------------------------------------------

    // FUNCTION | Setup All Event Listeners
    // ------------------------------------------------------------
    function setupEventListeners() {
        setupMouseEventListeners();                                            // <-- Setup mouse interactions
        setupKeyboardEventListeners();                                         // <-- Setup keyboard shortcuts
        setupTouchEventListeners();                                            // <-- Setup touch interactions
        setupWheelEventListeners();                                            // <-- Setup mouse wheel zoom
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Mouse Event Listeners
    // ---------------------------------------------------------------
    function setupMouseEventListeners() {
        canvasElement.addEventListener('mousedown', handleMouseDown);           // <-- Handle mouse down
        canvasElement.addEventListener('mousemove', handleMouseMove);           // <-- Handle mouse move
        canvasElement.addEventListener('mouseup', handleMouseUp);               // <-- Handle mouse up
        canvasElement.addEventListener('mouseleave', handleMouseLeave);         // <-- Handle mouse leave
        canvasElement.addEventListener('dblclick', handleDoubleClick);          // <-- Handle double click
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Keyboard Event Listeners
    // ---------------------------------------------------------------
    function setupKeyboardEventListeners() {
        document.addEventListener('keydown', handleKeyDown);                    // <-- Handle key down events
        document.addEventListener('keyup', handleKeyUp);                        // <-- Handle key up events
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Touch Event Listeners
    // ---------------------------------------------------------------
    function setupTouchEventListeners() {
        canvasElement.addEventListener('touchstart', handleTouchStart);         // <-- Handle touch start
        canvasElement.addEventListener('touchmove', handleTouchMove);           // <-- Handle touch move
        canvasElement.addEventListener('touchend', handleTouchEnd);             // <-- Handle touch end
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Setup Wheel Event Listeners
    // ---------------------------------------------------------------
    function setupWheelEventListeners() {
        canvasElement.addEventListener('wheel', handleWheel, { passive: false }); // <-- Handle mouse wheel
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Mouse Down Events
    // ---------------------------------------------------------------
    function handleMouseDown(event) {
        event.preventDefault();                                                // <-- Prevent default behavior

        const rect = canvasElement.getBoundingClientRect();                    // <-- Get canvas bounds
        canvasNavigationState.lastMouseX = event.clientX - rect.left;          // <-- Store mouse X
        canvasNavigationState.lastMouseY = event.clientY - rect.top;           // <-- Store mouse Y

        const middleButton = event.button === 1;                               // <-- Middle mouse button
        const spacePan     = event.button === 0 && spacebarHeld;               // <-- Spacebar + left click

        if (middleButton || spacePan) {                                       // <-- Activate pan
            canvasNavigationState.isPanning = true;                            // <-- Enable pan mode
            canvasElement.style.cursor = 'grabbing';                           // <-- Change cursor
            updatePanModeIndicator(true);                                      // <-- Update UI indicator
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Mouse Move Events
    // ---------------------------------------------------------------
    function handleMouseMove(event) {
        if (!canvasNavigationState.isPanning) return;                          // <-- Exit if not panning
        
        event.preventDefault();                                                // <-- Prevent default behavior
        
        const rect = canvasElement.getBoundingClientRect();                    // <-- Get canvas bounds
        const currentX = event.clientX - rect.left;                            // <-- Current mouse X
        const currentY = event.clientY - rect.top;                             // <-- Current mouse Y
        
        const deltaX = (currentX - canvasNavigationState.lastMouseX) * canvasNavigationState.panSpeed; // <-- Calculate X delta
        const deltaY = (currentY - canvasNavigationState.lastMouseY) * canvasNavigationState.panSpeed; // <-- Calculate Y delta
        
        panViewport(deltaX, deltaY);                                           // <-- Apply pan movement
        
        canvasNavigationState.lastMouseX = currentX;                           // <-- Update last mouse X
        canvasNavigationState.lastMouseY = currentY;                           // <-- Update last mouse Y
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Mouse Up Events
    // ---------------------------------------------------------------
    function handleMouseUp(event) {
        if (canvasNavigationState.isPanning) {                                 // <-- If panning was active
            canvasNavigationState.isPanning = false;                           // <-- Disable pan mode
            canvasElement.style.cursor = 'grab';                               // <-- Reset cursor
            updatePanModeIndicator(false);                                     // <-- Update UI indicator
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Mouse Leave Events
    // ---------------------------------------------------------------
    function handleMouseLeave(event) {
        handleMouseUp(event);                                                  // <-- Same as mouse up
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Double Click Events
    // ---------------------------------------------------------------
    function handleDoubleClick(event) {
        event.preventDefault();                                                // <-- Prevent default behavior
        
        const rect = canvasElement.getBoundingClientRect();                    // <-- Get canvas bounds
        const clickX = event.clientX - rect.left;                              // <-- Click X position
        const clickY = event.clientY - rect.top;                               // <-- Click Y position
        
        zoomToPoint(clickX, clickY, 2.0);                                      // <-- Zoom in at click point
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Wheel Events
    // ---------------------------------------------------------------
    function handleWheel(event) {
        event.preventDefault();                                                // <-- Prevent default scrolling
        
        const rect = canvasElement.getBoundingClientRect();                    // <-- Get canvas bounds
        const wheelX = event.clientX - rect.left;                              // <-- Wheel X position
        const wheelY = event.clientY - rect.top;                               // <-- Wheel Y position
        
        const zoomFactor = event.deltaY > 0 ? 0.9 : 1.1;                       // <-- Determine zoom direction
        zoomToPoint(wheelX, wheelY, zoomFactor);                               // <-- Zoom at wheel position
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Key Down Events
    // ---------------------------------------------------------------
    function handleKeyDown(event) {
        const key = event.key.toLowerCase();                                   // <-- Get lowercase key
        
        switch (key) {
            case '=':
            case '+':
                if (event.ctrlKey) {                                           // <-- Ctrl + Plus
                    event.preventDefault();                                    // <-- Prevent default
                    zoomIn();                                                  // <-- Zoom in
                }
                break;
            case '-':
                if (event.ctrlKey) {                                           // <-- Ctrl + Minus
                    event.preventDefault();                                    // <-- Prevent default
                    zoomOut();                                                 // <-- Zoom out
                }
                break;
            case '0':
                if (event.ctrlKey) {                                           // <-- Ctrl + 0
                    event.preventDefault();                                    // <-- Prevent default
                    resetView();                                               // <-- Reset view
                }
                break;
            case 'f':
                if (event.ctrlKey) {                                           // <-- Ctrl + F
                    event.preventDefault();                                    // <-- Prevent default
                    fitToScreen();                                             // <-- Fit to screen
                }
                break;
            case ' ':                                                          // <-- Spacebar
                event.preventDefault();                                        // <-- Prevent default
                spacebarHeld = true;                                           // <-- Hold space for temporary pan
                break;
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Key Up Events
    // ---------------------------------------------------------------
    function handleKeyUp(event) {
        const key = event.key.toLowerCase();                                   // <-- Get lowercase key
        
        if (key === ' ') {                                                    // <-- Spacebar released
            spacebarHeld = false;                                             // <-- Clear state
            if (canvasNavigationState.isPanning) {                             // <-- If panning was active
                handleMouseUp(event);                                          // <-- Stop panning
            }
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Touch Start Events
    // ---------------------------------------------------------------
    function handleTouchStart(event) {
        if (event.touches.length === 1) {                                      // <-- Single touch
            const touch = event.touches[0];                                    // <-- Get touch data
            const rect = canvasElement.getBoundingClientRect();                // <-- Get canvas bounds
            
            canvasNavigationState.lastMouseX = touch.clientX - rect.left;      // <-- Store touch X
            canvasNavigationState.lastMouseY = touch.clientY - rect.top;       // <-- Store touch Y
            canvasNavigationState.isPanning = true;                            // <-- Enable pan mode
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Touch Move Events
    // ---------------------------------------------------------------
    function handleTouchMove(event) {
        if (event.touches.length === 1 && canvasNavigationState.isPanning) {   // <-- Single touch panning
            event.preventDefault();                                            // <-- Prevent default
            const touch = event.touches[0];                                    // <-- Get touch data
            const rect = canvasElement.getBoundingClientRect();                // <-- Get canvas bounds
            
            const currentX = touch.clientX - rect.left;                        // <-- Current touch X
            const currentY = touch.clientY - rect.top;                         // <-- Current touch Y
            
            const deltaX = (currentX - canvasNavigationState.lastMouseX) * canvasNavigationState.panSpeed; // <-- Calculate X delta
            const deltaY = (currentY - canvasNavigationState.lastMouseY) * canvasNavigationState.panSpeed; // <-- Calculate Y delta
            
            panViewport(deltaX, deltaY);                                       // <-- Apply pan movement
            
            canvasNavigationState.lastMouseX = currentX;                       // <-- Update last touch X
            canvasNavigationState.lastMouseY = currentY;                       // <-- Update last touch Y
        }
    }
    // ---------------------------------------------------------------

    // HELPER FUNCTION | Handle Touch End Events
    // ---------------------------------------------------------------
    function handleTouchEnd(event) {
        canvasNavigationState.isPanning = false;                               // <-- Disable pan mode
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Viewport Transformation and Rendering
// -----------------------------------------------------------------------------

    // FUNCTION | Apply Viewport Transformations to Canvas Context
    // ------------------------------------------------------------
    function applyViewportTransform() {
        if (!canvasContext) return;                                            // <-- Exit if no context
        
        canvasContext.save();                                                  // <-- Save current context state
        canvasContext.clearRect(0, 0, canvasElement.width, canvasElement.height); // <-- Clear canvas
        
        // Apply transformations
        canvasContext.translate(canvasNavigationState.viewportX, canvasNavigationState.viewportY); // <-- Apply pan offset
        canvasContext.scale(canvasNavigationState.zoomLevel, canvasNavigationState.zoomLevel); // <-- Apply zoom scale
        
        return canvasContext;                                                  // <-- Return transformed context
    }
    // ---------------------------------------------------------------

    // FUNCTION | Restore Canvas Context After Rendering
    // ------------------------------------------------------------
    function restoreViewportTransform() {
        if (!canvasContext) return;                                            // <-- Exit if no context
        
        canvasContext.restore();                                               // <-- Restore context state
    }
    // ---------------------------------------------------------------

    // FUNCTION | Convert Screen Coordinates to World Coordinates
    // ------------------------------------------------------------
    function screenToWorld(screenX, screenY) {
        const worldX = (screenX - canvasNavigationState.viewportX) / canvasNavigationState.zoomLevel; // <-- Convert X
        const worldY = (screenY - canvasNavigationState.viewportY) / canvasNavigationState.zoomLevel; // <-- Convert Y
        return { x: worldX, y: worldY };                                       // <-- Return world coordinates
    }
    // ---------------------------------------------------------------

    // FUNCTION | Convert World Coordinates to Screen Coordinates
    // ------------------------------------------------------------
    function worldToScreen(worldX, worldY) {
        const screenX = worldX * canvasNavigationState.zoomLevel + canvasNavigationState.viewportX; // <-- Convert X
        const screenY = worldY * canvasNavigationState.zoomLevel + canvasNavigationState.viewportY; // <-- Convert Y
        return { x: screenX, y: screenY };                                     // <-- Return screen coordinates
    }
    // ---------------------------------------------------------------

    // FUNCTION | Update Canvas Dimensions
    // ------------------------------------------------------------
    function updateCanvasDimensions() {
        if (!canvasElement || !canvasContainer) return;                        // <-- Exit if elements missing
        
        const containerRect = canvasContainer.getBoundingClientRect();         // <-- Get container bounds
        canvasNavigationState.canvasWidth = containerRect.width;               // <-- Update canvas width
        canvasNavigationState.canvasHeight = containerRect.height;             // <-- Update canvas height
        
        // Set canvas size to match container
        canvasElement.width = canvasNavigationState.canvasWidth;               // <-- Set canvas width
        canvasElement.height = canvasNavigationState.canvasHeight;             // <-- Set canvas height
        
        // Update viewport constraints
        updateViewportConstraints();                                           // <-- Update viewport limits
    }
    // ---------------------------------------------------------------

    // FUNCTION | Setup Canvas Resize Observer
    // ------------------------------------------------------------
    function setupCanvasResizeObserver() {
        if (!canvasContainer) return;                                          // <-- Exit if container missing
        
        const resizeObserver = new ResizeObserver(() => {                      // <-- Create resize observer
            updateCanvasDimensions();                                          // <-- Update dimensions on resize
            requestRedraw();                                                   // <-- Request canvas redraw
        });
        
        resizeObserver.observe(canvasContainer);                               // <-- Observe container changes
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Zoom and Pan Operations
// -----------------------------------------------------------------------------

    // FUNCTION | Zoom In at Current Center
    // ------------------------------------------------------------
    function zoomIn() {
        const centerX = canvasNavigationState.canvasWidth / 2;                 // <-- Calculate center X
        const centerY = canvasNavigationState.canvasHeight / 2;                // <-- Calculate center Y
        zoomToPoint(centerX, centerY, 1.0 + canvasNavigationState.zoomStep);   // <-- Zoom in at center
    }
    // ---------------------------------------------------------------

    // FUNCTION | Zoom Out at Current Center
    // ------------------------------------------------------------
    function zoomOut() {
        const centerX = canvasNavigationState.canvasWidth / 2;                 // <-- Calculate center X
        const centerY = canvasNavigationState.canvasHeight / 2;                // <-- Calculate center Y
        zoomToPoint(centerX, centerY, 1.0 - canvasNavigationState.zoomStep);   // <-- Zoom out at center
    }
    // ---------------------------------------------------------------

    // FUNCTION | Zoom to Specific Point
    // ------------------------------------------------------------
    function zoomToPoint(screenX, screenY, zoomFactor) {
        const oldZoom = canvasNavigationState.zoomLevel;                       // <-- Store old zoom level
        const newZoom = Math.max(canvasNavigationState.minZoom,                // <-- Calculate new zoom level
                                Math.min(canvasNavigationState.maxZoom, oldZoom * zoomFactor));
        
        if (newZoom === oldZoom) return;                                       // <-- Exit if zoom unchanged
        
        // Calculate zoom center in world coordinates
        const worldCenter = screenToWorld(screenX, screenY);                   // <-- Convert to world coordinates
        
        // Update zoom level
        canvasNavigationState.zoomLevel = newZoom;                             // <-- Set new zoom level
        
        // Adjust viewport to keep zoom center fixed
        const newScreenCenter = worldToScreen(worldCenter.x, worldCenter.y);   // <-- Convert back to screen
        canvasNavigationState.viewportX += screenX - newScreenCenter.x;        // <-- Adjust viewport X
        canvasNavigationState.viewportY += screenY - newScreenCenter.y;        // <-- Adjust viewport Y
        
        // Apply constraints
        updateViewportConstraints();                                           // <-- Update viewport limits
        
        // Update UI and request redraw
        updateNavigationControlStates();                                       // <-- Update button states
        requestRedraw();                                                       // <-- Request canvas redraw
    }
    // ---------------------------------------------------------------

    // FUNCTION | Pan Viewport by Delta
    // ---------------------------------------------------------------
    function panViewport(deltaX, deltaY) {
        canvasNavigationState.viewportX += deltaX;                             // <-- Apply X pan
        canvasNavigationState.viewportY += deltaY;                             // <-- Apply Y pan
        
        updateViewportConstraints();                                           // <-- Update viewport limits
        requestRedraw();                                                       // <-- Request canvas redraw
    }
    // ---------------------------------------------------------------

    // FUNCTION | Reset Viewport to Default
    // ------------------------------------------------------------
    function resetViewportToDefault() {
        canvasNavigationState.viewportX = 0;                                   // <-- Reset X offset
        canvasNavigationState.viewportY = 0;                                   // <-- Reset Y offset
        canvasNavigationState.zoomLevel = 1.0;                                // <-- Reset zoom level
        
        updateViewportConstraints();                                           // <-- Update viewport limits
        updateNavigationControlStates();                                       // <-- Update button states
        requestRedraw();                                                       // <-- Request canvas redraw
    }
    // ---------------------------------------------------------------

    // FUNCTION | Reset View (Public Interface)
    // ------------------------------------------------------------
    function resetView() {
        resetViewportToDefault();                                              // <-- Reset to default state
    }
    // ---------------------------------------------------------------

    // FUNCTION | Fit Content to Screen
    // ------------------------------------------------------------
    function fitToScreen() {
        if (!canvasNavigationState.contentBounds) return;                      // <-- Exit if no content bounds
        
        const contentWidth = canvasNavigationState.contentBounds.maxX - canvasNavigationState.contentBounds.minX; // <-- Calculate content width
        const contentHeight = canvasNavigationState.contentBounds.maxY - canvasNavigationState.contentBounds.minY; // <-- Calculate content height
        
        if (contentWidth <= 0 || contentHeight <= 0) return;                   // <-- Exit if invalid content size
        
        const scaleX = canvasNavigationState.canvasWidth / contentWidth;       // <-- Calculate X scale
        const scaleY = canvasNavigationState.canvasHeight / contentHeight;     // <-- Calculate Y scale
        const scale = Math.min(scaleX, scaleY) * 0.9;                         // <-- Use smaller scale with margin
        
        canvasNavigationState.zoomLevel = Math.max(canvasNavigationState.minZoom, // <-- Set zoom level
                                                  Math.min(canvasNavigationState.maxZoom, scale));
        
        // Center content
        const centerX = (canvasNavigationState.contentBounds.minX + canvasNavigationState.contentBounds.maxX) / 2; // <-- Content center X
        const centerY = (canvasNavigationState.contentBounds.minY + canvasNavigationState.contentBounds.maxY) / 2; // <-- Content center Y
        
        const screenCenter = worldToScreen(centerX, centerY);                  // <-- Convert to screen coordinates
        canvasNavigationState.viewportX = canvasNavigationState.canvasWidth / 2 - screenCenter.x; // <-- Center viewport X
        canvasNavigationState.viewportY = canvasNavigationState.canvasHeight / 2 - screenCenter.y; // <-- Center viewport Y
        
        updateViewportConstraints();                                           // <-- Update viewport limits
        updateNavigationControlStates();                                       // <-- Update button states
        requestRedraw();                                                       // <-- Request canvas redraw
    }
    // ---------------------------------------------------------------

    // FUNCTION | Toggle Pan Mode
    // ------------------------------------------------------------
    function togglePanMode() {
        canvasNavigationState.isPanning = !canvasNavigationState.isPanning;    // <-- Toggle pan state
        canvasElement.style.cursor = canvasNavigationState.isPanning ? 'grabbing' : 'grab'; // <-- Update cursor
        updatePanModeIndicator(canvasNavigationState.isPanning);               // <-- Update UI indicator
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Viewport Constraints and Validation
// -----------------------------------------------------------------------------

    // FUNCTION | Update Viewport Constraints
    // ------------------------------------------------------------
    function updateViewportConstraints() {
        // Calculate content bounds if not set
        if (!canvasNavigationState.contentBounds || 
            (canvasNavigationState.contentBounds.maxX === 0 && canvasNavigationState.contentBounds.maxY === 0)) {
            calculateContentBounds();                                          // <-- Calculate content bounds
        }
        
        const bounds = canvasNavigationState.contentBounds;                    // <-- Get content bounds
        const zoom = canvasNavigationState.zoomLevel;                          // <-- Get current zoom
        
        // Calculate viewport limits
        const minViewportX = canvasNavigationState.canvasWidth - bounds.maxX * zoom; // <-- Minimum viewport X
        const maxViewportX = -bounds.minX * zoom;                              // <-- Maximum viewport X
        const minViewportY = canvasNavigationState.canvasHeight - bounds.maxY * zoom; // <-- Minimum viewport Y
        const maxViewportY = -bounds.minY * zoom;                              // <-- Maximum viewport Y
        
        // Apply constraints
        canvasNavigationState.viewportX = Math.max(minViewportX, Math.min(maxViewportX, canvasNavigationState.viewportX)); // <-- Constrain X
        canvasNavigationState.viewportY = Math.max(minViewportY, Math.min(maxViewportY, canvasNavigationState.viewportY)); // <-- Constrain Y
    }
    // ---------------------------------------------------------------

    // FUNCTION | Calculate Content Bounds
    // ------------------------------------------------------------
    function calculateContentBounds() {
        // Default bounds if no content
        canvasNavigationState.contentBounds = {                                // <-- Set default bounds
            minX: -100,                                                        // <-- Minimum X
            minY: -100,                                                        // <-- Minimum Y
            maxX: 100,                                                         // <-- Maximum X
            maxY: 100                                                          // <-- Maximum Y
        };
        
        // TODO: Implement actual content bounds calculation based on loaded DXF data
        // This should be called when DXF content is loaded and updated
    }
    // ---------------------------------------------------------------

    // FUNCTION | Set Content Bounds (Public Interface)
    // ------------------------------------------------------------
    function setContentBounds(minX, minY, maxX, maxY) {
        canvasNavigationState.contentBounds = {                                // <-- Set content bounds
            minX: minX,                                                        // <-- Minimum X
            minY: minY,                                                        // <-- Minimum Y
            maxX: maxX,                                                        // <-- Maximum X
            maxY: maxY                                                         // <-- Maximum Y
        };
        
        updateViewportConstraints();                                           // <-- Update viewport limits
        requestRedraw();                                                       // <-- Request canvas redraw
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | UI State Management and Updates
// -----------------------------------------------------------------------------

    // FUNCTION | Update Navigation Control States
    // ------------------------------------------------------------
    function updateNavigationControlStates() {
        updateZoomLevelDisplay();                                              // <-- Update zoom percentage
        updateButtonStates();                                                  // <-- Update button enabled states
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Update Zoom Level Display
    // ---------------------------------------------------------------
    function updateZoomLevelDisplay() {
        const zoomDisplay = document.getElementById('zoom-level-display');     // <-- Get zoom display element
        if (zoomDisplay) {                                                     // <-- If element exists
            const percentage = Math.round(canvasNavigationState.zoomLevel * 100); // <-- Calculate percentage
            zoomDisplay.textContent = `${percentage}%`;                        // <-- Update display text
        }
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Update Button States
    // ---------------------------------------------------------------
    function updateButtonStates() {
        // Update zoom buttons based on zoom limits
        if (zoomInButton) {                                                    // <-- If zoom in button exists
            zoomInButton.disabled = canvasNavigationState.zoomLevel >= canvasNavigationState.maxZoom; // <-- Disable if at max
        }
        
        if (zoomOutButton) {                                                   // <-- If zoom out button exists
            zoomOutButton.disabled = canvasNavigationState.zoomLevel <= canvasNavigationState.minZoom; // <-- Disable if at min
        }
    }
    // ---------------------------------------------------------------

    // SUB FUNCTION | Update Pan Mode Indicator
    // ---------------------------------------------------------------
    function updatePanModeIndicator(isPanning) {
        const indicator = document.getElementById('pan-mode-indicator');       // <-- Get indicator element
        if (indicator) {                                                       // <-- If element exists
            indicator.textContent = `Pan Mode: ${isPanning ? 'On' : 'Off'}`;  // <-- Update indicator text
            indicator.className = `pan-mode-indicator ${isPanning ? 'active' : ''}`; // <-- Update CSS class
        }
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Rendering and Redraw Management
// -----------------------------------------------------------------------------

    // FUNCTION | Request Canvas Redraw
    // ------------------------------------------------------------
    function requestRedraw() {
        if (canvasNavigationState.animationFrameId) {                          // <-- If animation frame pending
            cancelAnimationFrame(canvasNavigationState.animationFrameId);      // <-- Cancel existing frame
        }
        
        canvasNavigationState.animationFrameId = requestAnimationFrame(() => { // <-- Schedule redraw
            redrawCanvas();                                                    // <-- Perform redraw
            canvasNavigationState.animationFrameId = null;                     // <-- Clear frame ID
        });
    }
    // ---------------------------------------------------------------

    // FUNCTION | Redraw Canvas with Current Viewport
    // ------------------------------------------------------------
    function redrawCanvas() {
        if (!canvasContext) return;                                            // <-- Exit if no context
        
        const transformedContext = applyViewportTransform();                   // <-- Apply transformations
        if (!transformedContext) return;                                       // <-- Exit if transform failed
        
        // Call registered redraw callback if available
        if (window.canvasRedrawCallback && typeof window.canvasRedrawCallback === 'function') {
            window.canvasRedrawCallback();                                    // <-- Call registered callback
        } else {
            // Fallback: clear canvas and show message
            canvasContext.clearRect(0, 0, canvasElement.width, canvasElement.height); // <-- Clear canvas
            canvasContext.fillStyle = '#666666';                              // <-- Set text color
            canvasContext.font = '16px Arial';                                // <-- Set font
            canvasContext.fillText('No content to display', 50, 50);          // <-- Show message
        }
        
        restoreViewportTransform();                                           // <-- Restore context state
    }
    // ---------------------------------------------------------------

    // FUNCTION | Get Current Viewport State (Public Interface)
    // ------------------------------------------------------------
    function getViewportState() {
        return {                                                               // <-- Return viewport state
            viewportX: canvasNavigationState.viewportX,                        // <-- Viewport X offset
            viewportY: canvasNavigationState.viewportY,                        // <-- Viewport Y offset
            zoomLevel: canvasNavigationState.zoomLevel,                        // <-- Current zoom level
            isPanning: canvasNavigationState.isPanning                         // <-- Pan mode state
        };
    }
    // ---------------------------------------------------------------

    // FUNCTION | Set Viewport State (Public Interface)
    // ------------------------------------------------------------
    function setViewportState(state) {
        if (state.viewportX !== undefined) {                                   // <-- If X offset provided
            canvasNavigationState.viewportX = state.viewportX;                 // <-- Set viewport X
        }
        if (state.viewportY !== undefined) {                                   // <-- If Y offset provided
            canvasNavigationState.viewportY = state.viewportY;                 // <-- Set viewport Y
        }
        if (state.zoomLevel !== undefined) {                                   // <-- If zoom level provided
            canvasNavigationState.zoomLevel = Math.max(canvasNavigationState.minZoom, // <-- Constrain zoom level
                                                      Math.min(canvasNavigationState.maxZoom, state.zoomLevel));
        }
        
        updateViewportConstraints();                                           // <-- Update viewport limits
        updateNavigationControlStates();                                       // <-- Update UI states
        requestRedraw();                                                       // <-- Request redraw
    }
    // ---------------------------------------------------------------

// endregion -------------------------------------------------------------------

// -----------------------------------------------------------------------------
// REGION | Public API Export
// -----------------------------------------------------------------------------

    // FUNCTION | Get Canvas Element (Public Interface)
    // ------------------------------------------------------------
    function getCanvasElement() {
        return canvasElement;                                                 // <-- Return canvas element reference
    }
    // ------------------------------------------------------------

    // FUNCTION | Set Canvas Redraw Callback (Public Interface)
    // ------------------------------------------------------------
    function setCanvasRedrawCallback(callback) {
        if (typeof callback === 'function') {                                 // <-- Validate callback is function
            window.canvasRedrawCallback = callback;                          // <-- Store callback globally
            console.log('Canvas redraw callback registered');                 // <-- Log registration
        }
    }
    // ------------------------------------------------------------

    // Export functions to global scope for integration
    window.initializeCanvasNavigation = initializeCanvasNavigation;           // <-- Export initialization function
    window.getCanvasElement = getCanvasElement;                              // <-- Export canvas getter
    window.setCanvasRedrawCallback = setCanvasRedrawCallback;                // <-- Export callback setter
    window.applyViewportTransform = applyViewportTransform;                   // <-- Export transform function
    window.restoreViewportTransform = restoreViewportTransform;               // <-- Export restore function
    window.screenToWorld = screenToWorld;                                     // <-- Export coordinate conversion
    window.worldToScreen = worldToScreen;                                     // <-- Export coordinate conversion
    window.getViewportState = getViewportState;                               // <-- Export state getter
    window.setViewportState = setViewportState;                               // <-- Export state setter
    window.setContentBounds = setContentBounds;                               // <-- Export bounds setter
    window.zoomIn = zoomIn;                                                   // <-- Export zoom functions
    window.zoomOut = zoomOut;                                                 // <-- Export zoom functions
    window.resetView = resetView;                                             // <-- Export reset function
    window.fitToScreen = fitToScreen;                                         // <-- Export fit function
    window.togglePanMode = togglePanMode;                                     // <-- Export pan toggle
    window.requestRedraw = requestRedraw;                                     // <-- Export redraw function

// endregion -------------------------------------------------------------------
