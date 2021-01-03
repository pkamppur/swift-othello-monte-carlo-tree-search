//
//  ViewController.swift
//  Othello
//
//  Created by Petteri Kamppuri on 25.3.2016.
//  Copyright © 2016 Petteri Kamppuri. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var othelloView: OthelloView!
    @IBOutlet weak var whiteScoreLabel: UILabel!
    @IBOutlet weak var blackScoreLabel: UILabel!
    @IBOutlet weak var turnTextLabel: UILabel!
    @IBOutlet weak var winningTextLabel: UILabel!
    @IBOutlet weak var boardMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var aiInfoLabel: UILabel!
    
    private var interactor: OthelloInteractor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interactor = OthelloInteractor()
        interactor.listener = self
        
        aiInfoLabel.font = UIFont.monospacedDigitSystemFont(ofSize: aiInfoLabel.font.pointSize, weight: .regular)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBoardMargin(view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateBoardMargin(size)
    }
    
    private func updateBoardMargin(_ size: CGSize) {
        boardMarginConstraint.constant = floor(size.width * 0.025)
    }
}

private extension ViewController {
    @IBAction func boardTapped(_ tapRecognizer: UITapGestureRecognizer) {
        let move = othelloView.moveFromPoint(tapRecognizer.location(in: othelloView))
        
        interactor.makePlayerMove(move)
    }
    
    @IBAction func toggleShowTips(_ sender: AnyObject) {
        interactor.showTips = !interactor.showTips
    }
}

extension ViewController: OthelloInteractorListener {
    func didUpdate(viewModel: OthelloViewModel) {
        othelloView.board = viewModel.board
        
        whiteScoreLabel.text = viewModel.whiteScoreText
        blackScoreLabel.text = viewModel.blackScoreText
        
        turnTextLabel.text = viewModel.turnText
        turnTextLabel.isHidden = !viewModel.isTurnTextVisible
        winningTextLabel.text = viewModel.winningText
        winningTextLabel.isHidden = !viewModel.isWinningTextVisible
        
        othelloView.highlightedSquares = viewModel.highlightedSquares
        othelloView.highlightedMoves = viewModel.highlightedMoves
        
        aiInfoLabel.text = viewModel.aiInfo
    }
}
