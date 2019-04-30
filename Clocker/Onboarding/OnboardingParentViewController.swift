// Copyright © 2015 Abhishek Banthia

import Cocoa
import ServiceManagement

extension NSStoryboard.SceneIdentifier {
    static let welcomeIdentifier = NSStoryboard.SceneIdentifier("welcomeVC")
    static let onboardingPermissionsIdentifier = NSStoryboard.SceneIdentifier("onboardingPermissionsVC")
    static let startAtLoginIdentifier = NSStoryboard.SceneIdentifier("startAtLoginVC")
    static let onboardingSearchIdentifier = NSStoryboard.SceneIdentifier("onboardingSearchVC")
    static let finalOnboardingIdentifier = NSStoryboard.SceneIdentifier("finalOnboardingVC")
}

private enum OnboardingType: Int {
    case welcome
    case permissions
    case launchAtLogin
    case search
    case final
    case complete // Added for logging purposes
}

class OnboardingParentViewController: NSViewController {
    @IBOutlet private var containerView: NSView!
    @IBOutlet private var negativeButton: NSButton!
    @IBOutlet private var backButton: NSButton!
    @IBOutlet private var positiveButton: NSButton!

    private lazy var welcomeVC: WelcomeViewController? = (storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.welcomeIdentifier) as? WelcomeViewController)

    private lazy var permissionsVC: OnboardingPermissionsViewController? = (storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.onboardingPermissionsIdentifier) as? OnboardingPermissionsViewController)

    private lazy var startAtLoginVC: StartAtLoginViewController? = (storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.startAtLoginIdentifier) as? StartAtLoginViewController)

    private lazy var onboardingSearchVC: OnboardingSearchController? = (self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.onboardingSearchIdentifier) as? OnboardingSearchController)

    private lazy var finalOnboardingVC: FinalOnboardingViewController? = (self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier.finalOnboardingIdentifier) as? FinalOnboardingViewController)

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupWelcomeScreen()
        setupUI()
    }

    private func setupWelcomeScreen() {
        guard let firstVC = welcomeVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(firstVC)
        containerView.addSubview(firstVC.view)
        firstVC.view.frame = containerView.bounds
    }

    private func setupUI() {

        setIdentifiersForTests()
        
        positiveButton.title = "Get Started"
        positiveButton.tag = OnboardingType.welcome.rawValue
        backButton.tag = OnboardingType.welcome.rawValue

        [negativeButton, backButton].forEach { $0?.isHidden = true }
    }
    
    private func setIdentifiersForTests() {
        positiveButton.setAccessibilityIdentifier("Forward")
        negativeButton.setAccessibilityIdentifier("Alternate")
        backButton.setAccessibilityIdentifier("Backward")
    }

    @IBAction func negativeAction(_: Any) {
        guard let fromViewController = startAtLoginVC, let toViewController = onboardingSearchVC else {
            assertionFailure()
            return
        }

        addChildIfNeccessary(toViewController)

        shouldStartAtLogin(false)

        transition(from: fromViewController,
                   to: toViewController,
                   options: .slideLeft) {
            self.positiveButton.tag = OnboardingType.search.rawValue
            self.backButton.tag = OnboardingType.launchAtLogin.rawValue
            self.positiveButton.title = "Continue"
            self.negativeButton.isHidden = true
        }
    }

    @IBAction func continueOnboarding(_: NSButton) {
        if positiveButton.tag == OnboardingType.welcome.rawValue {
            guard let fromViewController = welcomeVC, let toViewController = permissionsVC else {
                assertionFailure()
                return
            }

            addChildIfNeccessary(toViewController)

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideLeft) {
                self.positiveButton.tag = OnboardingType.permissions.rawValue
                self.positiveButton.title = "Continue"
                self.backButton.isHidden = false
            }

        } else if positiveButton.tag == OnboardingType.permissions.rawValue {
            guard let fromViewController = permissionsVC, let toViewController = startAtLoginVC else {
                assertionFailure()
                return
            }

            addChildIfNeccessary(toViewController)

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideLeft) {
                self.backButton.tag = OnboardingType.permissions.rawValue
                self.positiveButton.tag = OnboardingType.launchAtLogin.rawValue
                self.positiveButton.title = "Open Clocker At Login"
                self.negativeButton.isHidden = false
            }
        } else if positiveButton.tag == OnboardingType.launchAtLogin.rawValue {
            guard let fromViewController = startAtLoginVC, let toViewController = onboardingSearchVC else {
                assertionFailure()
                return
            }

            addChildIfNeccessary(toViewController)

            shouldStartAtLogin(true)

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideLeft) {
                self.backButton.tag = OnboardingType.launchAtLogin.rawValue
                self.positiveButton.tag = OnboardingType.search.rawValue
                self.positiveButton.title = "Continue"
                self.negativeButton.isHidden = true
            }
        } else if positiveButton.tag == OnboardingType.search.rawValue {
            guard let fromViewController = onboardingSearchVC, let toViewController = finalOnboardingVC else {
                assertionFailure()
                return
            }

            addChildIfNeccessary(toViewController)

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideLeft) {
                self.backButton.tag = OnboardingType.search.rawValue
                self.positiveButton.tag = OnboardingType.final.rawValue
                self.positiveButton.title = "Launch Clocker"
            }

        } else {
            
            self.positiveButton.tag = OnboardingType.complete.rawValue
            
            // Install the menubar option!
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            appDelegate?.continueUsually()
            
            view.window?.close()
            
            if ProcessInfo.processInfo.arguments.contains(CLOnboaringTestsLaunchArgument) == false {
                UserDefaults.standard.set(true, forKey: CLShowOnboardingFlow)
            }
        }
    }
    
    private func addChildIfNeccessary(_ vc: NSViewController) {
        if children.contains(vc) == false {
            addChild(vc)
        }
    }

    @IBAction func back(_: Any) {
        if backButton.tag == OnboardingType.welcome.rawValue {
            guard let fromViewController = permissionsVC, let toViewController = welcomeVC else {
                assertionFailure()
                return
            }

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideRight) {
                self.positiveButton.tag = OnboardingType.welcome.rawValue
                self.backButton.isHidden = true
                self.positiveButton.title = "Get Started"
            }
        } else if backButton.tag == OnboardingType.permissions.rawValue {
            // We're on StartAtLogin VC and we have to go back to Permissions

            guard let fromViewController = startAtLoginVC, let toViewController = permissionsVC else {
                assertionFailure()
                return
            }

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideRight) {
                self.positiveButton.tag = OnboardingType.permissions.rawValue
                self.backButton.tag = OnboardingType.welcome.rawValue
                self.negativeButton.isHidden = true
                self.positiveButton.title = "Continue"
            }
        } else if backButton.tag == OnboardingType.launchAtLogin.rawValue {
            guard let fromViewController = onboardingSearchVC, let toViewController = startAtLoginVC else {
                assertionFailure()
                return
            }

            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideRight) {
                self.positiveButton.tag = OnboardingType.launchAtLogin.rawValue
                self.backButton.tag = OnboardingType.permissions.rawValue
                self.positiveButton.title = "Open Clocker At Login"
                self.negativeButton.isHidden = false
            }
        } else if backButton.tag == OnboardingType.search.rawValue {
            
            guard let fromViewController = finalOnboardingVC, let toViewController = onboardingSearchVC else {
                assertionFailure()
                return
            }
            
            transition(from: fromViewController,
                       to: toViewController,
                       options: .slideRight) {
                        self.positiveButton.tag = OnboardingType.search.rawValue
                        self.backButton.tag = OnboardingType.launchAtLogin.rawValue
                        self.positiveButton.title = "Continue"
                        self.negativeButton.isHidden = true
            }
            
        }
    }

    private func shouldStartAtLogin(_ shouldStart: Bool) {
        
        // If tests are going on, we don't want to enable/disable launch at login!
        if ProcessInfo.processInfo.arguments.contains(CLOnboaringTestsLaunchArgument) {
            return
        }
        
        UserDefaults.standard.set(shouldStart ? 1 : 0, forKey: CLStartAtLogin)

        if !SMLoginItemSetEnabled("com.abhishek.ClockerHelper" as CFString, shouldStart) {
            Logger.log(object: ["Successful": "NO"], for: "Start Clocker Login")
        } else {
            Logger.log(object: ["Successful": "YES"], for: "Start Clocker Login")
        }
        
        if shouldStart {
            Logger.log(object: [:], for: "Enable Launch at Login while Onboarding")
        } else {
            Logger.log(object: [:], for: "Disable Launch at Login while Onboarding")
        }
    }
    
    func logExitPoint() {
        let currentViewController = currentController()
        print(currentViewController)
        Logger.log(object: currentViewController, for: "Onboarding Process Exit")
    }
    
    private func currentController() -> [String: String] {
        
        switch positiveButton.tag {
        case 0:
            return ["Onboarding Process Interrupted": "Welcome View"]
        case 1:
            return ["Onboarding Process Interrupted": "Onboarding Permissions View"]
        case 2:
            return ["Onboarding Process Interrupted": "Start At Login View"]
        case 3:
            return ["Onboarding Process Interrupted": "Onboarding Search View"]
        case 4:
            return ["Onboarding Process Interrupted": "Finish Onboarding View"]
        case 5:
            return ["Onboarding Process Completed": "Successfully"]
        default:
             return ["Onboarding Process Interrupted": "Error"]
        }
    }
}