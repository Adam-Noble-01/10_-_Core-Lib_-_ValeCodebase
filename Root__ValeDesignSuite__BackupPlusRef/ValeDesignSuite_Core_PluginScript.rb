# =============================================================================
# ValeDesignSuite - Core Plugin Script
# =============================================================================
#
# NAMESPACE : ValeDesignSuite
# MODULE    : Core
# AUTHOR    : Adam Noble - Vale Garden Houses
# TYPE      : SketchUp 2025 Main Plugin Script
# PURPOSE   : Main entry point for the ValeDesignSuite Plugin functionality
# CREATED   : 20-May-2025
#
# DESCRIPTION:
# - This is the main plugin script for the Vale Design Suite plugin
# - Initializes the plugin's functionality and UI components
# - Called by the loader script when SketchUp starts
#
# USAGE NOTES: 
# - This file should not be directly executed
# - Loaded automatically by ValeDesignSuite_LoaderScript.rb
# 
# IMPORTANT CONSIDERATIONS: 
# - Keep initialization logic here, move specific tool functionality to dedicated files
# - Ensures proper loading sequence and dependency management
# 
# LOADING SEQUENCE NOTES: 
# - This script is loaded by the loader script when SketchUp starts.
# - The simple pre-loader script only points to this file (ValeDesignSuite_Core_PluginScript.rb)
# - All other file loading is handled within this file.
# - The pre-loader script is located in the parent directory of this file. (One level up).
#
# - *Absolute Path For The Pre-Loader Script:*
#   - `C:\Users\adamw\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins\ValeDesignSuite_LoaderScript.rb`
#
# - *Relative Path For Pre-Loader Script:*
#   - `../ValeDesignSuite_LoaderScript.rb`
#
# USER INTERFACE:
# - The main user interface is located in the `ValeDesignSuite_Core_MainUserInterface.rb` file.
# - This script is simply responsible for loading the plugin and initializing the UI.
# - All UI HTML / CSS / JS is located embedded within the `ValeDesignSuite_Core_MainUserInterface.rb` file.
# - This keeps the main plugin script clean and easy to maintain in once place as its not too extensive to warrant multiple files.
#
# -----------------------------------------------------------------------------
#
# DEVELOPMENT LOG:
# 20-May-2025 - Version 0.0.1 - INITIAL SETUP
# - Created basic plugin script structure
# - Added simple success dialog for testing
#
# 21-May-2025 - Version 0.0.2 - FURTHER PRELIMINARY DEVELOPMENT
# - Added external stylesheet for consistent UI styling
# - Implemented Vale brand colors and typography
# - Fixed font loading issues with paths
#
# 21-May-2025 - Version 0.0.5 - FURTHER PRELIMINARY DEVELOPMENT
# - Added Command & Shortcut Setup
# - Added Toolbar Setup
# - Cleaned up the plugin script structure
#
# 29-May-2025 - Version 0.0.6 - DEBUG TOOLS REFACTORING
# - Moved debug functionality to PluginDebuggingAndDiagnosticTools
# - Updated initialization to use new debug tools
#
# 26-May-2025 - Version 0.0.7 - DEBUG CONFIGURATION SYSTEM
# - Added global debug configuration system
# - Integrated debug menu items for easy debug mode control
#
# =============================================================================

# Load required libraries first
require 'sketchup'
require_relative 'Tools_FrameworkTools/ValeDesignSuite_Tools_FrameworkToolsConfigurator' # Added for Framework Configurator
require_relative 'ValeDesignSuite_Core_PluginDebuggingAndDiagnosticTools'
require_relative 'Config_PluginConfigFiles/ValeDesignSuite_Core_DebugConfiguration'

# Create the ValeDesignSuite module (namespace)
module ValeDesignSuite

    # Create the Core module
    module Core
        # Debug tools are now loaded via the main require statement above
    end

    # CONSTANTS - Plugin Directory Structure Configuration
    # -------------------------------------------------------------------------
    PLUGIN_ROOT           =    File.dirname(__FILE__)                       # <-- This returns the directory of the current file.
    PLUGIN_CONFIG_DATA    =    File.join(PLUGIN_ROOT, 'Config_PluginConfigFiles')  # <-- This is the Directory that contains Plugin Configuration Data Json Files.
    PLUGIN_ASSETS         =    File.join(PLUGIN_ROOT, 'Assets_PluginAssets')       # <-- This is the Directory that contains General Plugin Assets, Images, Icons, etc.
    BRAND_ASSETS          =    File.join(PLUGIN_ROOT, 'Assets_ValeBrandAssets')    # <-- This is the Directory that contains Vale Graphics & Branding Assets.
    VALE_PRODUCT_DATA     =    File.join(PLUGIN_ROOT, 'Config_ValeProductData')    # <-- This is the Directory that contains Vale Product Json Data Files.
    # -------------------------------------------------------------------------

  
    # LOADING SCHEDULER |  Initialize the plugin when module is loaded
    # -------------------------------------------------------------------------
    def self.initialize_plugin
        begin
        # Log debug information using PluginDebuggingAndDiagnosticTools
        Core::PluginDebuggingAndDiagnosticTools.debug_paths
        
        # LOAD MODULE |  Load & Validate the Roof Lantern Tools Module
        # -------------------------------------------------------------
        begin
            require_relative 'Tools_RoofLanternConfigurator/ValeDesignSuite_Tools_RoofLanternTools'
            Config::DebugConfiguration.debug_log("Successfully loaded RoofLanternTools", "LOAD")
        rescue LoadError => e
            Config::DebugConfiguration.debug_error("Failed to load RoofLanternTools", e)
        end

        # LOAD MODULE |  Load & Validate the Main User Interface Module
        # -------------------------------------------------------------
        begin
            require_relative 'ValeDesignSuite_Core_MainUserInterface.rb'
            Config::DebugConfiguration.debug_log("Successfully loaded MainUserInterface", "LOAD")
        rescue LoadError => e
            Config::DebugConfiguration.debug_error("Failed to load MainUserInterface", e)
            UI.messagebox("Failed to load the Vale Design Suite interface. Please check the Ruby Console for details.")
        rescue => e
            Config::DebugConfiguration.debug_error("Error loading MainUserInterface", e)
            UI.messagebox("Error loading Vale Design Suite interface. Please check the Ruby Console for details.")
        end
        
        rescue => e
        Config::DebugConfiguration.debug_error("Error in initialize_plugin", e)
        UI.messagebox("Error initializing Vale Design Suite. Please check the Ruby Console for details.")
        end
    end

    # NEW METHOD | Show the main dialog (separate from initialization)
    # -------------------------------------------------------------------------
    def self.show_main_dialog
        begin
            # Ensure the plugin is initialized first
            initialize_plugin unless @plugin_initialized
            @plugin_initialized = true
            
            # Now show the dialog
            ValeDesignSuite::MainUserInterface.show_main_dialog
        rescue => e
            Config::DebugConfiguration.debug_error("Error showing main dialog", e)
            UI.messagebox("Error showing Vale Design Suite dialog. Please check the Ruby Console for details.")
        end
    end

    # OBSERVER | Run initialization when SketchUp is ready
    # -------------------------------------------------------------
    class AppObserver < ::Sketchup::AppObserver
        def onAppInitialized
        Config::DebugConfiguration.debug_log("AppObserver: SketchUp initialization complete, starting ValeDesignSuite", "INIT")
        ValeDesignSuite.initialize_plugin
        end
    end
    # -------------------------------------------------------------


  # -------------------------------------------------------------------------
  # SKETCHUP UI - Plugin Initialization and Menu Setup
  # -------------------------------------------------------------------------
  unless file_loaded?(__FILE__)
    Config::DebugConfiguration.debug_log("Registering ValeDesignSuite menu items and observers...", "INIT")
    
    # -------------------------------------------------------------------------
    # COMMAND & SHORTCUT SETUP
    # -------------------------------------------------------------------------
    # Added in Version 0.0.5 - 21-May-2025
    # Create the command that will be triggered by both menu and shortcut
    cmd = UI::Command.new("VGH | Vale Design Suite") {
      ValeDesignSuite.show_main_dialog
    }
    
    # Print existing shortcuts for debugging
    Config::DebugConfiguration.debug_log("Existing shortcuts: #{Sketchup.get_shortcuts}", "INIT")

    # Set command properties
    cmd.small_icon = File.join(PLUGIN_ASSETS, "Icons_ValeIcons", "Vale_Icon16px.png")
    cmd.large_icon = File.join(PLUGIN_ASSETS, "Icons_ValeIcons", "Vale_Icon32px.png")
    
    # Debug icon paths using PluginDebuggingAndDiagnosticTools
    Core::PluginDebuggingAndDiagnosticTools.debug_icon_paths
    
    cmd.tooltip = "Open Vale Design Suite"
    cmd.status_bar_text = "Opens the Vale Design Suite interface"
    
    # Add the command to the Extensions menu
    UI.menu("Extensions").add_item(cmd)
    
    # -------------------------------------------------------------------------
    # TOOLBAR SETUP
    # -------------------------------------------------------------------------
    # Create a new toolbar
    toolbar = UI::Toolbar.new "Vale Design Suite"
    # Add the command to the toolbar
    toolbar.add_item cmd
    # Show the toolbar
    toolbar.show
    # -------------------------------------------------------------------------
    
    # -------------------------------------------------------------------------
    # DEBUG MENU SETUP
    # -------------------------------------------------------------------------
    # Initialize debug menu items for easy debug mode control
    Config::DebugConfiguration.add_debug_menu_items
    # -------------------------------------------------------------------------
    
    # -------------------------------------------------------------------------
    # OBSERVER SETUP
    # -------------------------------------------------------------------------
    # Register the observer to handle SketchUp initialization
    ::Sketchup.add_observer(AppObserver.new)
    Config::DebugConfiguration.debug_log("ValeDesignSuite initialization complete", "INIT")
    
    # Ensure SketchUp UI is ready before adding menu items
    # We use a flag to ensure this block runs only once.
    if !defined?(@framework_config_menu_added)
      UI.start_timer(0.1, false) do
        ValeDesignSuite::Tools::FrameworkToolsConfigurator.add_menu_item
      end
      @framework_config_menu_added = true
    end
    
    file_loaded(__FILE__)
  end
  
  # Make the roof lantern generator available in our namespace
  def self.generate_roof_lantern
    RoofLanternTools.generate_roof_lantern
  end
  
end # module ValeDesignSuite

# =============================================================================
# END OF FILE
# ============================================================================= 