//
//  BlackjackGameViewController.swift
//  BlackJack
//
//  Created by Sameer Totey on 2/2/15.
//  Copyright (c) 2015 Sameer Totey. All rights reserved.
//

import UIKit

typealias KVOContext = UInt8
var MyObservationContext = KVOContext()

class BlackjackGameViewController: UIViewController, CardPlayerObserver, UIDynamicAnimatorDelegate {
    
    lazy var modalTransitioningDelegate = ModalPresentationTransitionVendor()
    
    var blackjackGame: BlackjackGame!
    var currentPlayer: Player!
    var gameConfiguration: GameConfiguration!
    var audioController: AudioController!
    var theDealer: Dealer!
    var previousBet: Double = 0.0
    var currentBet: Double = 0.0 {
        didSet {
            switch currentBet {
            case let x where x < gameConfiguration.minimumBet:
                statusLabel.text = "Minimum bet: \(gameConfiguration.minimumBet)"
                dealNewButton.hidden = true
            case let x where x > gameConfiguration.maximumBet:
                statusLabel.text = "Maximum bet: \(gameConfiguration.maximumBet)"
                currentBet = gameConfiguration.maximumBet
                dealNewButton.hidden = false
            case let x where x >= gameConfiguration.minimumBet:
                statusLabel.text = "Bet Ready"
                rebetButton.hidden = true
                dealNewButton.hidden = false
            default:
                println("Default")
            }
            currentBetButton.setTitle("\(currentBet)", forState: .Normal)
            currentBetButton.animate()
            let difference = currentBet - oldValue
            if difference > 0 {
                currentPlayer.bet(difference)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        blackjackGame = BlackjackGame()
        currentPlayer = Player(name: "Sameer")
        currentPlayer.observer = self
        currentPlayer.bankRoll = 100.00
        currentPlayer.delegate = blackjackGame
        playerBankRollButton.setTitle("\(currentPlayer.bankRoll)", forState: .Normal)
        theDealer = Dealer()
        setGameConfiguration()
        theDealer.cardSource = blackjackGame
        theDealer.observer = dealerHandContainerViewController
        blackjackGame.dealer = theDealer
        
        setupSubViews()
        playerFinishedHandsVC = [playerFinishedHand1ViewController!, playerFinishedHand2ViewController!, playerFinishedHand3ViewController!]
        playerSplitHandsVC = [playerSplit1ViewController!, playerSplit2ViewController!, playerSplit3ViewController!]
        blackjackGame.play()
        hideAllPlayerButtons()
        setupButtons()
        audioController = AudioController()
        currentBet = gameConfiguration.minimumBet
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCardProgress:", name: "cardShoeContentStatus", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameCompleted", name: "dealerHandOver", object: nil)
        startObservingBankroll(currentPlayer)
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        stopObservingBankroll(currentPlayer)
    }
    func updateCardProgress(notification: NSNotification) {
        var progress: NSNumber = notification.object as NSNumber
        cardShoeProgressView.setProgress(progress.floatValue, animated: true)
    }
    
    func setGameConfiguration() {
        gameConfiguration = GameConfiguration()
        blackjackGame.gameConfiguration = gameConfiguration
        theDealer.gameConfiguration = gameConfiguration
        AudioController.GameSounds.soundEffectsEnabled = gameConfiguration.enableSoundEffects
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    /*
    Normally an unwind segue will pop/dismiss the view controller but this doesn't happen
    for custom modal transitions so we have to manually call dismiss.
    */
    
    @IBAction func returnToGameViewController(segue:UIStoryboardSegue) {
        // return here from game configuration using unwind segue
        if let identifier = segue.identifier {
            switch identifier {
            case "SaveFromConfiguration":
                setGameConfiguration()
                fallthrough
            case "CancelFromConfiguration":
                dismissViewControllerAnimated(true, completion: nil)
            default: break
            }
        }
    }

    var dealerHandContainerViewController: DealerHandContainerViewController?
    var playerHandContainerViewController: PlayerHandContainerViewController?
    var playerFinishedHand1ViewController: PlayerHandContainerViewController?
    var playerFinishedHand2ViewController: PlayerHandContainerViewController?
    var playerFinishedHand3ViewController: PlayerHandContainerViewController?
    var playerSplit1ViewController: PlayerHandContainerViewController?
    var playerSplit2ViewController: PlayerHandContainerViewController?
    var playerSplit3ViewController: PlayerHandContainerViewController?
    
    var playerFinishedHandsVC: [PlayerHandContainerViewController] = []
    var playerSplitHandsVC: [PlayerHandContainerViewController] = []
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "Present Game Configuration":
                if segue.destinationViewController is UINavigationController {
                    let toVC = segue.destinationViewController as UINavigationController
                    toVC.modalPresentationStyle = .Custom
                    toVC.transitioningDelegate = self.modalTransitioningDelegate
                }
            case "Dealer Container":
                dealerHandContainerViewController = segue.destinationViewController as? DealerHandContainerViewController
                dealerHandContainerViewController!.cardShoeContainer = cardShoeContainerView
            case "Player Container":
                playerHandContainerViewController = segue.destinationViewController as? PlayerHandContainerViewController
                playerHandContainerViewController!.cardShoeContainer = cardShoeContainerView
            case "Finished Hand 1":
                playerFinishedHand1ViewController = segue.destinationViewController as? PlayerHandContainerViewController
            case "Finished Hand 2":
                playerFinishedHand2ViewController = segue.destinationViewController as? PlayerHandContainerViewController
            case "Finished Hand 3":
                playerFinishedHand3ViewController = segue.destinationViewController as? PlayerHandContainerViewController
            case "Split Hand 1":
                playerSplit1ViewController = segue.destinationViewController as? PlayerHandContainerViewController
                playerSplit1ViewController?.cardWidthDivider = 1.0
                playerSplit1ViewController?.numberOfCardsPerWidth = 1.0
            case "Split Hand 2":
                playerSplit2ViewController = segue.destinationViewController as? PlayerHandContainerViewController
                playerSplit2ViewController?.cardWidthDivider = 1.0
                playerSplit2ViewController?.numberOfCardsPerWidth = 1.0
            case "Split Hand 3":
                playerSplit3ViewController = segue.destinationViewController as? PlayerHandContainerViewController
                playerSplit3ViewController?.cardWidthDivider = 1.0
                playerSplit3ViewController?.numberOfCardsPerWidth = 1.0
            default: break
            }
        }
    }
    
    // MARK: - Gesture Recognizers
    
    @IBOutlet weak var dealerContainerView: UIView!
    @IBOutlet weak var dealerHandView: UIView!
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var playerHandView: UIView!
    
    @IBOutlet var finishedHandContainerViews: [UIView]!
    var finishedHandViewCards: [[BlackjackCard]] = []
    
    @IBOutlet var splitHandContainerViews: [UIView]!
    var splitHandViewCards: [BlackjackCard] = []       // There is only one card per split hand view
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var playerBankRollButton: GameActionButton!
    
    @IBOutlet weak var doubleDownButton: GameActionButton!
    @IBOutlet weak var splitHandButton: GameActionButton!
    @IBOutlet weak var surrenderButton: GameActionButton!
    @IBOutlet weak var buyInsuranceButton: GameActionButton!
    @IBOutlet weak var declineInsuranceButton: GameActionButton!
    @IBOutlet weak var hitButton: GameActionButton!
    @IBOutlet weak var standButton: GameActionButton!
    
    @IBOutlet weak var currentBetButton: GameActionButton!
    
    @IBOutlet weak var chip100Button: GameActionButton!
    @IBOutlet weak var chip25Button: GameActionButton!
    @IBOutlet weak var chip5Button: GameActionButton!
    @IBOutlet weak var chip1Button: GameActionButton!
    @IBOutlet weak var rebetButton: GameActionButton!
    @IBOutlet weak var dealNewButton: GameActionButton!
    
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var buttonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerheightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dealerHandViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dealerHandViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerHandViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerHandViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var finishedHandsViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var finishedHandsViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var splitHandsViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var splitHandsViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cardShoeContainerView: UIView!
    @IBOutlet weak var cardShoeProgressView: UIProgressView!
    
    private var animator: UIDynamicAnimator?
    private var snapBehavior: UISnapBehavior?
    private var pushBehavior: UIPushBehavior?
    private var itemBehavior: UIDynamicItemBehavior?
    
    // Actions

    func setupSubViews() {
//        playerContainerView.clipsToBounds = true
//        dealerContainerView.clipsToBounds = true
    }
    
    func setupButtons () {
        switch blackjackGame.gameState {
        case .Deal:
            setupButtonsForDeal()
        case .Players:
            setupButtonsForPlay()
        default:
            println("This should not happen, you should be in only Deal or Player state")
        }
      }
    
    let position0 = CGPointMake(0, 0)
    

    let positions = [CGPointMake(30.0, 70.0), CGPointMake(100.0, 70.0), CGPointMake(170.0, 70.0), CGPointMake(30.0, 20.0), CGPointMake(100.0, 20.0), CGPointMake(170.0, 20.0)]

    
    func setupButtonsForDeal() {
        var buttons: [GameActionButton] = []
        buttons.append(chip1Button)
        buttons.append(chip5Button)
        buttons.append(dealNewButton)
        buttons.append(chip25Button)
        buttons.append(chip100Button)
        buttons.append(rebetButton)

        setButtonsAndMessage(buttons, message: "Play Blackjack")
        bankrollUpdate()
        
        if previousBet == 0.0 {
            rebetButton.hidden = true
        }
        
    }
    
    func setButtonsAndMessage(buttons: [GameActionButton], message: String?) {
        for index in 0..<buttons.count {
            buttons[index].hidden = false
            buttons[index].center = position0
        }
        
        UIView.animateWithDuration(0.25, delay: 0.8, options: .CurveEaseOut, animations: {
            for index in 0..<buttons.count {
                buttons[index].center = self.positions[index]
            }
            }) { _ in
                if message != nil {
                    self.statusLabel.text = message
                }
        }
    }
    
    func setupButtonsForPlay() {
        var buttons: [GameActionButton] = []
        buttons.append(hitButton)
        buttons.append(standButton)
        if let currentPlayerHand = currentPlayer.currentHand {
            if currentPlayerHand.cards.count == 2 {
                buttons.append(doubleDownButton)
                if currentPlayerHand.initialCardPair {
                    if currentPlayer.hands.count < gameConfiguration.maxHandsWithSplits {
                        buttons.append(splitHandButton)
                    }
                }
            }
        }
        
        if currentPlayer.insuranceAvailable {
            buttons.append(buyInsuranceButton)
            buttons.append(declineInsuranceButton)
        } else {
            if currentPlayer.surrenderOptionAvailabe {
                buttons.append(surrenderButton)
            }
        }
        var message: String?
        switch currentPlayer.previousAction {
        case .BuyInsurance:
            message = "Insurance complete"
        case .DeclineInsurance:
            message = "Insurance declined"
        case .Bet:
            message = "Make a move"
        case .Hit:
            message = "Hit last hand"
        case .Stand:
            message = "Stood last hand"
        case .Surrender:
            message = "Surrendered last hand"
        case .DoubleDown:
            message = "Double Down last hand"
        default:
            message = nil
        }
        setButtonsAndMessage(buttons, message: message)
    }
    
    func hideAllPlayerButtons() {
        for subView in buttonContainerView.subviews {
            if subView is GameActionButton {
                (subView as GameActionButton).hidden = true
            }
        }
    }
    
    
    @IBAction func playerActionButtonTouchUpInside(sender: GameActionButton) {
        if readyForNextAction() {
            switch sender {
            case chip1Button:
                animateChip(sender.imageForState(.Normal), amount: 1.0)
            case chip5Button:
                animateChip(sender.imageForState(.Normal), amount: 5.0)
            case chip25Button:
                animateChip(sender.imageForState(.Normal), amount: 25.0)
            case chip100Button:
                animateChip(sender.imageForState(.Normal), amount: 100.0)
            case currentBetButton:
                currentPlayer.bankRoll += currentBet
                currentBet = 0
            case dealNewButton:
                deal()
            case rebetButton:
                currentBet = previousBet
                deal()
            default:
                println("received touch from unknown sender: \(sender)")
            }
        }
    }
    
    func animateChip(chipImage: UIImage?, amount: Double) {
        let chipImageView = UIImageView(image: chipImage)
        chipImageView.frame = CGRectMake(0, 0, 1.0, 1.0)
        let finalSize = CGRectMake(0, 0, 40.0, 40.0)
        chipImageView.layer.cornerRadius = 20.0
        chipImageView.clipsToBounds = true
        chipImageView.center = playerBankRollButton.center
        playerContainerView.addSubview(chipImageView)
        chipImageView.alpha = 0.1
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            chipImageView.frame.size = finalSize.size
            chipImageView.center = self.playerBankRollButton.center
            chipImageView.alpha = 1.0
            self.currentBetButton.alpha = 0.1
            }) { _ in
                self.chipDynamicBehaviors(chipImageView, amount: amount)
                AudioController.play(.Coin)
        }
    }
    
    private func chipDynamicBehaviors(chipView: UIImageView, amount: Double) {
        if animator == nil {
            animator = UIDynamicAnimator(referenceView: playerContainerView)
            animator!.delegate = self
        }
        pushBehavior = UIPushBehavior(items: [chipView], mode: .Instantaneous)
        pushBehavior!.pushDirection = CGVectorMake(0.8, 0.4)
        pushBehavior!.magnitude = 2
        animator!.addBehavior(pushBehavior)
        
        snapBehavior = UISnapBehavior(item: chipView, snapToPoint: currentBetButton.center)
        snapBehavior!.damping = 0.5
        animator!.addBehavior(snapBehavior)
        dynamicChipViews.append(chipView)
        currentBet += amount
    }
    
    private var dynamicChipViews: [UIImageView] = []
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        animator.removeAllBehaviors()
        
        UIView.transitionWithView(currentBetButton, duration: 0.2, options: .CurveEaseOut | .TransitionFlipFromLeft, animations: {
            for aChipView in self.dynamicChipViews {
                self.currentBetButton.alpha = 1.0
                aChipView.removeFromSuperview()
            }
            }, completion: { _ in
        })
    }
    
    func dynamicAnimatorWillResume(animator: UIDynamicAnimator) {
    }

    func deal() {
        hideAllPlayerButtons()
        if blackjackGame.gameState == .Deal {
            currentPlayer.currentBet = currentBet
            previousBet = currentBet
            currentBetButton.enabled = false
            resetCardViews()
            blackjackGame.deal()
            blackjackGame.update()
            setupButtons()
        }
    }
    
    
    func resetCardViews() {
        finishedHandViewCards.removeAll(keepCapacity: true)
        splitHandViewCards.removeAll(keepCapacity: true)
        dealerHandContainerViewController?.reset()
        playerHandContainerViewController?.reset()
        for index in 0..<3 {
            playerSplitHandsVC[index].reset()
            playerFinishedHandsVC[index].reset()
        }
    }
      
    @IBAction func hitButtonTouchUpInside(sender: UIButton) {
        performHit()
     }
    
    func performHit() {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.hit()
            setupButtons()
        }
    }
   
    @IBAction func standButtonTouchUpInside(sender: UIButton) {
        performStand()
     }
    
    func performStand() {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.stand()
            setupButtons()
        }
    }
    
    @IBAction func doubleButtonTouchUpInside(sender: UIButton) {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.doubleDown()
            setupButtons()
        }
     }

    @IBAction func splitHandButtonTouchUpInside(sender: UIButton) {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.split()
            setupButtons()
        }
    }
    
    @IBAction func surrenderButtonTouchUpInside(sender: UIButton) {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.surrenderHand()
            setupButtons()
        }
    }
    
    @IBAction func buyInsuranceButtonTouchUpInside(sender: UIButton) {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.buyInsurance()
            setupButtons()
        }
    }
    
    @IBAction func declineInsuranceButtonTouchUpInside(sender: UIButton) {
        if readyForNextAction() {
            hideAllPlayerButtons()
            currentPlayer.declineInsurance()
            setupButtons()
        }
    }
    
    // MARK: - Card Player Observer
    
    func currentHandStatusUpdate(hand: BlackjackHand) {
        playerHandContainerViewController?.setPlayerScoreText(hand.valueDescription)
    }
    
    func addCardToCurrentHand(card: BlackjackCard)  {
        playerHandContainerViewController?.playerHandIndex = currentPlayer.currentHandIndex
        playerHandContainerViewController?.addCardToPlayerHand(card)
    }
    
    func addnewlySplitHand(card: BlackjackCard) {
        if let cardViewCard = playerHandContainerViewController?.removeLastCard(true) {
            let splitHandsCount = splitHandViewCards.count
            playerSplitHandsVC[splitHandsCount].addCardToPlayerHand(card)
            splitHandViewCards.insert(cardViewCard, atIndex: splitHandsCount)
        }
    }
    
    func switchHands() {
        println("Advance to next hand....")
        let finishedHandsCount = finishedHandViewCards.count    // This is an array of array of cards, two dimentional array
        var finishedHandViewCardsItem: [BlackjackCard] = []
        let savedPlayerText = playerHandContainerViewController?.getPlayerScoreText()
        
        if let cardViewCard = playerHandContainerViewController?.removeFirstCard() {
            var removedCardViewCard: BlackjackCard? = cardViewCard
            playerFinishedHandsVC[finishedHandsCount].playerHandIndex = playerHandContainerViewController!.playerHandIndex
            if let scoreText = savedPlayerText {
                playerFinishedHandsVC[finishedHandsCount].setPlayerScoreText(scoreText)
            }
            do {
                playerFinishedHandsVC[finishedHandsCount].addCardToPlayerHand(removedCardViewCard!)
                finishedHandViewCardsItem.append(removedCardViewCard!)
                removedCardViewCard = playerHandContainerViewController?.removeFirstCard()
            } while removedCardViewCard != nil
        }
        finishedHandViewCards.append(finishedHandViewCardsItem)
        playerHandContainerViewController?.reset()

        // find the next split hand card....
        for splitVCIndex in 0..<3 {
            if let cardViewCard = playerSplitHandsVC[splitVCIndex].removeLastCard(true) {
                println("Advanced to next hand in between....")
                addCardToCurrentHand(cardViewCard)
                break
            }
        }
        
        // Now that we have switched the hand, we should hit on the split hand
        println("Advanced to next hand complete..Auto Hit..")

        currentPlayer.hit()
    }
    
    func bankrollUpdate() {
        // should KVO be used here???
        playerBankRollButton.setTitle("\(currentPlayer.bankRoll)", forState: .Normal)
        playerBankRollButton.animate()
        println("Bankroll is now \(currentPlayer.bankRoll) ")
    }
    

    // MARK: - Blackjack Game Delegate
    func gameCompleted() {
        currentBet = 0
        if gameConfiguration.autoWagerPreviousBet {
            currentBet = previousBet
        }
        statusLabel.text = "Game Over!"
        currentBetButton.enabled = true
        
        playerHandContainerViewController!.displayResult(currentPlayer.hands[playerHandContainerViewController!.playerHandIndex!].handState)
        for finishedHandsIndex in 0..<3 {
            if let handIndex = playerFinishedHandsVC[finishedHandsIndex].playerHandIndex {
                playerFinishedHandsVC[finishedHandsIndex].displayResult(currentPlayer.hands[handIndex].handState)
            }
        }
        if currentPlayer!.currentHandIndex == 0 {
            var gameSound: AudioController.GameSound
            switch currentPlayer!.hands[0].handState{
            case .Won, .NaturalBlackjack:
                gameSound = .Won
            case .Lost:
                gameSound = .Lost
            default:
                gameSound = .Tied
            }
            AudioController.play(gameSound)
        }
    }
    
    func zoomStatusLabel() {
        statusLabel.alpha = 1.0
        statusLabel.hidden = false
        let label = statusLabel
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: nil, animations: {
//            label.alpha = 0
            label.transform = CGAffineTransformMakeScale(1.4, 1.8)
            }, completion: { _ in
//                label.hidden = true
                label.transform = CGAffineTransformIdentity
               
        })
    }

    
    func readyForNextAction() -> Bool {
      
        if let dealerVC = dealerHandContainerViewController {
            if dealerVC.busyNow() {
                println("hold on dealerAnimating")
                statusLabel.text = "Hold On Please - Dealer busy"
                zoomStatusLabel()
                AudioController.play(.Beep)
                return false
            }
        }
        if let playerVC = playerHandContainerViewController {
            if playerVC.busyNow() {
                println("hold on playerAnimating")
                statusLabel.text = "Hold On Please - busy"
                AudioController.play(.Beep)
                zoomStatusLabel()
                return false
            }
        }
        return true
    }
    
    func startObservingBankroll(player: Player) {
        let options = NSKeyValueObservingOptions.New | NSKeyValueObservingOptions.Old
        player.addObserver(self, forKeyPath: "bankRoll", options: options, context: &MyObservationContext)
    }
    
    func stopObservingBankroll(player: Player) {
        player.removeObserver(self, forKeyPath: "bankRoll", context: &MyObservationContext)
   
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch (keyPath, context) {
        case("bankRoll", &MyObservationContext):
            println("Bankroll changed: \(change)")
            bankrollUpdate()
            
        case(_, &MyObservationContext):
            assert(false, "unknown key path")
            
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    @IBAction func cardShoeLongPressed(sender: UILongPressGestureRecognizer) {
        println("Card shoe was long pressed")
        if sender.state == .Ended  && blackjackGame.gameState == .Deal {
            blackjackGame.getNewShoe()
        }
    }
    @IBAction func doubleTappedView(sender: UITapGestureRecognizer) {
        if sender.state == .Ended && blackjackGame.gameState == .Players {
            println("Double tapped the view")
            performHit()
        }
    }
    
    @IBAction func swipedTheView(sender: UISwipeGestureRecognizer) {
        if sender.state == .Ended && blackjackGame.gameState == .Players {
            println("swiped  the view")
            performStand()
        }

    }
}

