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
        
        self.interactor = OthelloInteractor()
        self.interactor.listener = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBoardMargin(self.view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateBoardMargin(size)
    }
    
    private func updateBoardMargin(_ size: CGSize) {
        self.boardMarginConstraint.constant = floor(size.width * 0.025)
    }
}

private extension ViewController {
    @IBAction func boardTapped(_ tapRecognizer: UITapGestureRecognizer) {
        let move = othelloView.moveFromPoint(tapRecognizer.location(in: othelloView))
        
        self.interactor.makePlayerMove(move)
    }
    
    @IBAction func toggleShowTips(_ sender: AnyObject) {
        self.interactor.showTips = !self.interactor.showTips
    }
}

extension ViewController: OthelloInteractorListener {
    func didUpdate(viewModel: OthelloViewModel) {
        self.othelloView.board = viewModel.board
        
        self.whiteScoreLabel.text = viewModel.whiteScoreText
        self.blackScoreLabel.text = viewModel.blackScoreText
        
        self.turnTextLabel.text = viewModel.turnText
        self.turnTextLabel.isHidden = !viewModel.isTurnTextVisible
        self.winningTextLabel.text = viewModel.winningText
        self.winningTextLabel.isHidden = !viewModel.isWinningTextVisible
        
        self.othelloView.highlightedSquares = viewModel.highlightedSquares
        self.othelloView.highlightedMoves = viewModel.highlightedMoves
        
        self.aiInfoLabel.text = viewModel.aiInfo
    }
}
