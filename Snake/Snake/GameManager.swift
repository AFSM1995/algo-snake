//
//  GameManager.swift
//  Snake
//
//  Created by Álvaro Santillan on 1/8/20.
//  Copyright © 2020 Álvaro Santillan. All rights reserved.
//  Bug Seg-fault when reach gameboard end.

//--------------------
// Create tuple data structure.
struct Tuple {
    var x: Int
    var y: Int
}

// Make the tuple hashable.
extension Tuple: Hashable {
    public var hashValue: Int {
        return x.hashValue ^ y.hashValue
    }
}

import SpriteKit
import AVFoundation

class GameManager {
    var player: AVAudioPlayer?
    var viewController: GameScreenViewController!
    var play = true
    var gameStarted = false
    var matrix = [[Int]]()
    var test = [Int]()
    var pathBlockCordinates = [(Int, Int)]()
    var onPathMode = false
    var scene: GameScene!
    var nextTime: Double?
    var gameSpeed: Float = 1
    var paused = false
    var playerDirection: Int = 4 // 1 == left, 2 == up, 3 == right, 4 == down
    var currentScore: Int = 0
    var barrierNodesWaitingToBeDisplayed = [Tuple]()
    var barrierNodesWaitingToBeRemoved = [Tuple]()
    var teeeemp = [(SKShapeNode, Tuple)]()
    var snakeBodyPos: [(Int, Int)] = []
    
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    // Takes a two dimentional matrix, determins the legal squares.
    // The results are converted into a nested dictionary.
    func gameBoardMatrixToDictionary(gameBoardMatrix: Array<Array<Int>>) -> Dictionary<Tuple, Dictionary<Tuple, Float>> {
        // Initialize the two required dictionaries.
        var mazeDictionary = [Tuple : [Tuple : Float]]()
        var vaildMoves = [Tuple : Float]()

        // Loop through every cell in the maze.
        for(y, matrixRow) in gameBoardMatrix.enumerated() {
            for(x, _) in matrixRow.enumerated() {
                // If in a square that is leagal, append valid moves to a dictionary.
                if (gameBoardMatrix[y][x] == 0 || gameBoardMatrix[y][x] == 2) {
                    let isYNegIndex = gameBoardMatrix.indices.contains(y-1)
                    let isYIndex = gameBoardMatrix.indices.contains(y+1)
                    let isXIndex = gameBoardMatrix.indices.contains(x+1)
                    
                        if isYNegIndex {
                            if (gameBoardMatrix[y-1][x] == 0 || gameBoardMatrix[y-1][x] == 2) {
                                vaildMoves[Tuple(x: x, y: y-1)] = 1
                            }
                        }
                        // Right
                        if isXIndex {
                            if (gameBoardMatrix[y][x+1] == 0 || gameBoardMatrix[y][x+1] == 2) {
                                // Floats so that we can have duplicates keys in dictinaries (Swift dictionary workaround).
                                vaildMoves[Tuple(x: x+1, y: y)] = 1.000001
                            }
                        }
                        // Left
                        if x-1 != -1 {
                            if (gameBoardMatrix[y][x-1] == 0 || gameBoardMatrix[y][x-1] == 2) {
                                vaildMoves[Tuple(x: x-1, y: y)] = 1.000002
                            }
                        }
                        // Down
                        if isYIndex {
                            if (gameBoardMatrix[y+1][x] == 0 || gameBoardMatrix[y+1][x] == 2) {
                                vaildMoves[Tuple(x: x, y: y+1)] = 1.000003
                                }
                            }
                    // Append the valid move dictionary to a master dictionary to create a dictionary of dictionaries.
                    mazeDictionary[Tuple(x: x, y: y)] = vaildMoves
                    // Reset the inner dictionary templet.
                    vaildMoves = [Tuple : Float]()
                }
            }
        }
        return mazeDictionary
    }

    // Genarate a path and optional statistics from the results of BFS.
    func formatSearchResults(squareAndParentSquare: [Tuple : Tuple], gameBoard: [Tuple : Dictionary<Tuple, Float>], currentSquare: Tuple, visitedSquareCount: Int, returnPathCost: Bool, returnSquaresVisited: Bool) -> ([Int], [(Int, Int)], Int, Int) {
        var squareAndParentSquareTuplePath = [Tuple : Tuple]()
        var squareAndNoParentArrayPath = [(Int, Int)]()
        // 1 == left, 2 == up, 3 == right, 4 == down
        var movePath = [Int]()

        // Find a path using the results of the search algorthim.
        func findPath(squareAndParentSquare: [Tuple : Tuple], currentSquare: Tuple) -> ([Int],[(Int, Int)],[Tuple : Tuple]) {
            if (currentSquare == Tuple(x:-1, y:-1)) {
                return (movePath, squareAndNoParentArrayPath, squareAndParentSquareTuplePath)
            } else {
                squareAndParentSquareTuplePath[currentSquare] = squareAndParentSquare[currentSquare]
                squareAndNoParentArrayPath.append((currentSquare.x,currentSquare.y))
                let xValue = currentSquare.x - squareAndParentSquare[currentSquare]!.x
                let yValue = currentSquare.y - squareAndParentSquare[currentSquare]!.y
                // 1 == left, 2 == up, 3 == right, 4 == down
                if (xValue == 0 && yValue == 1) {
                    movePath.append(2)
                // 1 == left, 2 == up, 3 == right, 4 == down
                } else if (xValue == 0 && yValue == -1) {
                    movePath.append(4)
                // 1 == left, 2 == up, 3 == right, 4 == down
                } else if (xValue == 1 && yValue == 0) {
                    movePath.append(1)
                // 1 == left, 2 == up, 3 == right, 4 == down
                } else if (xValue == -1 && yValue == 0) {
                    movePath.append(3)
                }
                
                findPath(squareAndParentSquare: squareAndParentSquare, currentSquare: squareAndParentSquare[currentSquare]!)
            }
            return (movePath, squareAndNoParentArrayPath, squareAndParentSquareTuplePath)
        }

        // Calculate the path cost of the path returned by the "findPath" function.
        func findPathCost(solutionPathDuple: [Tuple : Tuple], gameBoard: [Tuple : Dictionary<Tuple, Float>]) -> Int {
            var cost = 0
            
            for square in solutionPathDuple.keys {
                cost += Int(gameBoard[square]![solutionPathDuple[square]!] ?? 0)
            }
            return(cost)
        }
        let (solutionPathMoves, solutionPathArray, solutionPathDuple) = findPath(squareAndParentSquare: squareAndParentSquare, currentSquare: currentSquare)
        
        // Prepare and present the result returns.
        if (returnPathCost == true) {
            // Use the "path" method result to calculate a pathcost using the "pathcost" method.
            let solutionPathCost = findPathCost(solutionPathDuple: solutionPathDuple, gameBoard: gameBoard)
            
            if (returnSquaresVisited == true) {
                return (solutionPathMoves, squareAndNoParentArrayPath, solutionPathCost, visitedSquareCount)
            } else {
                return (solutionPathMoves, squareAndNoParentArrayPath, solutionPathCost, 0)
            }
        }
        else if (returnPathCost == false) && (returnSquaresVisited == true) {
            return (solutionPathMoves, squareAndNoParentArrayPath, 0, visitedSquareCount)
        }
        else {
            return (solutionPathMoves, squareAndNoParentArrayPath, 0, 0)
        }
    }
    
    var visitedNodeArray = [SKShapeNode]()
    var fronteerSquareArray = [SKShapeNode]()
    
    func colorVisitedSquares(visitedX: Int, visitedY: Int) {
        let node = scene.gameBoard.first(where: {$0.x == visitedX && $0.y == visitedY})?.node
        visitedNodeArray.append(node!)
//        node!.fillColor = UserDefaults.standard.colorForKey(key: "Visited Square")!
//        print("Node at:", visitedX, visitedY)
    }
    
        func fronteerSquares(visitedX: Int, visitedY: Int) {
            let node = scene.gameBoard.first(where: {$0.x == visitedY && $0.y == visitedX})?.node
            fronteerSquareArray.append(node!)
    //        node!.fillColor = UserDefaults.standard.colorForKey(key: "Visited Square")!
//            print("Node at:", visitedX, visitedY)
        }

    // Steps in Breath First Search
    // Mark parent
    // Mark current node as visited.
    // Append children nodes if needed to the fronter.
    // Select one by one a unvisited child node to explore.
    // Do this for all the child nodes
    // Repeat untill the goal is visited.

    // BFS produces a dictionary in which each valid square points too only one parent.
    // Then the dictionary is processed to create a valid path.
    // The nodes are traversed in order found in the dictionary parameter.
    func breathFirstSearch(startSquare: Tuple, goalSquare: Tuple, gameBoard: [Tuple : Dictionary<Tuple, Float>], returnPathCost: Bool, returnSquaresVisited: Bool) -> ([Int], [(Int, Int)], Int, Int) {
        // Initalize variable and add first square manually.
        var visitedSquares = [Tuple]()
        var fronterSquares = [startSquare]
        var currentSquare = startSquare
        var visitedSquareCount = 1
        var counter = 0
        // Dictionary used to find a path, every square will have only one parent.
        var squareAndParentSquare = [startSquare : Tuple(x:-1, y:-1)]
        
        // Break once the goal is reached (the goals parent is noted a cycle before when it was a new node.)
        while (currentSquare != goalSquare) {
            counter += 1
            // Mark current node as visited. (If statement required due to first node.)
            if !(visitedSquares.contains(currentSquare)) {
                visitedSquares += [currentSquare]
                colorVisitedSquares(visitedX: currentSquare.y, visitedY: currentSquare.x)
                visitedSquareCount += 1
            }
            
            // Repeat through all the nodes in the sub dictionary.
            // Append to fronter and mark parent.
            for (newFronterSquare, _) in gameBoard[currentSquare]! {
                if !(visitedSquares.contains(newFronterSquare)) {
                    fronterSquares += [newFronterSquare]
                    fronteerSquares(visitedX: newFronterSquare.y, visitedY: newFronterSquare.x)
                    squareAndParentSquare[newFronterSquare] = currentSquare
                }
            }
            // New currentNode is first in queue (BFS).
            currentSquare = fronterSquares[0]
            fronterSquares.remove(at: 0)
        }
        // Genarate a path and optional statistics from the results of BFS.
        return(formatSearchResults(squareAndParentSquare: squareAndParentSquare, gameBoard: gameBoard, currentSquare: goalSquare, visitedSquareCount: visitedSquareCount, returnPathCost: returnPathCost, returnSquaresVisited: returnSquaresVisited))
    }

    // Steps in Depth First Search
    // Mark parent
    // Mark current node as visited.
    // Append children nodes if needed to the fronter.
    // Select the last unvisited child node to explore.
    // Repeat untill the goal is visited.

    // DFS produces a dictionary in which each valid square points too only one parent.
    // Then the dictionary is processed to create a valid path.
    // The nodes are traversed in order found in the dictionary parameter.
    func depthFirstSearch(startSquare: Tuple, goalSquare: Tuple, gameBoard: [Tuple : Dictionary<Tuple, Float>], returnPathCost: Bool, returnSquaresVisited: Bool) -> ([Int], [(Int, Int)], Int, Int) {
        // Initalize variable and add first square manually.
        var visitedSquares = [Tuple]()
        var fronterSquares = [startSquare]
        var currentSquare = startSquare
        var visitedSquareCount = 1
        // Dictionary used to find a path, every square will have only one parent.
        var squareAndParentSquare = [startSquare : Tuple(x:-1, y:-1)]
        
        // Break once the goal is reached (the goals parent is noted a cycle before when it was a new node.)
        while (currentSquare != goalSquare) {
            // Mark current node as visited. (If statement required due to first node.)
            if !(visitedSquares.contains(currentSquare)) {
                visitedSquares += [currentSquare]
                colorVisitedSquares(visitedX: currentSquare.x, visitedY: currentSquare.y)
                visitedSquareCount += 1
            }
            
            // Repeat through all the nodes in the sub dictionary.
            // Append to fronter and mark parent.
            for (newFronterSquare, _) in gameBoard[currentSquare]! {
                if !(visitedSquares.contains(newFronterSquare)) {
                    fronterSquares += [newFronterSquare]
                    fronteerSquares(visitedX: newFronterSquare.y, visitedY: newFronterSquare.x)
                    squareAndParentSquare[newFronterSquare] = currentSquare
                }
            }
            
            if fronterSquares.count != 0 {
                currentSquare = fronterSquares.last!
                fronterSquares.popLast()
            } else {
//                print("DFS else hit")
                return(formatSearchResults(squareAndParentSquare: squareAndParentSquare, gameBoard: gameBoard, currentSquare: currentSquare, visitedSquareCount: visitedSquareCount, returnPathCost: returnPathCost, returnSquaresVisited: returnSquaresVisited))
            }
        }
        // Genarate a path and optional statistics from the results of DFS.
        return(formatSearchResults(squareAndParentSquare: squareAndParentSquare, gameBoard: gameBoard, currentSquare: goalSquare, visitedSquareCount: visitedSquareCount, returnPathCost: returnPathCost, returnSquaresVisited: returnSquaresVisited))
    }
    

    
    // Understood - Initiate the starting position of the snake.
    func initiateSnakeStartingPosition() {
        snakeBodyPos.append((3, 3))
        matrix[3][3] = 2
        snakeBodyPos.append((3, 4))
        matrix[3][4] = 1
        snakeBodyPos.append((3, 5))
        matrix[3][5] = 1
        snakeBodyPos.append((3, 6))
        matrix[3][5] = 1
        snakeBodyPos.append((3, 7))
        matrix[3][5] = 1
        snakeBodyPos.append((3, 8))
        matrix[3][5] = 1
        spawnFoodBlock()
        gameStarted = true
        
//        node.run(scene.gameSquareAnimation())
    }
    
    // Understood - Spawn a new food block into the game.
    var prevX = -1
    var prevY = -1
    var closetFoodBlockHit = false
    var foodLocationArray: [[Int]] = []
    var foodDistanceFromHead: [Int] = []
    var foodCollisionPoint = Int()
    let foodSpawnMax = (UserDefaults.standard.integer(forKey: "Food Count Setting"))
    let mainScreenAlgoChoice = UserDefaults.standard.integer(forKey: "Algorithim Choice")
    
    func spawnFoodBlock() {
        let foodPalletsNeeded = (foodSpawnMax - foodLocationArray.count)
        let snakeHead = snakeBodyPos[0]
        
        // need to use queue.
        for _ in 1...foodPalletsNeeded {
            let randomX = Int(arc4random_uniform(15)) //73
            let randomY = Int(arc4random_uniform(15)) //41
            matrix[randomX][randomY] = 2
            foodLocationArray.append([randomX,randomY])
            let DistanceFromSnake = abs(snakeHead.0 - randomX) + abs(snakeHead.1 - randomY)
            foodDistanceFromHead.append(DistanceFromSnake)
            scene.foodPosition.append(CGPoint(x: randomY, y: randomX))
            
        }
        // Calculation for closest food block is wrong mathamaticlly sometimes.
        let temp = foodDistanceFromHead.min()!
        let minX = foodLocationArray[foodDistanceFromHead.firstIndex(of: temp)!][0]
        let minY = foodLocationArray[foodDistanceFromHead.firstIndex(of: temp)!][1]
        
        let path: ([Int], [(Int, Int)], Int, Int)
        if (((prevX == -1) && prevY == -1) || closetFoodBlockHit == true) {
            closetFoodBlockHit = false
            if mainScreenAlgoChoice == 0 {
                test = []
            } else if mainScreenAlgoChoice == 1 {
                path = breathFirstSearch(startSquare: Tuple(x: Int(minY), y: Int(minX)), goalSquare: Tuple(x:snakeHead.1, y:snakeHead.0), gameBoard: gameBoardMatrixToDictionary(gameBoardMatrix: matrix), returnPathCost: false, returnSquaresVisited: false)
                test = path.0
                pathBlockCordinates = path.1
            } else if mainScreenAlgoChoice == 2 {
                path = depthFirstSearch(startSquare: Tuple(x: Int(minY), y: Int(minX)), goalSquare: Tuple(x:snakeHead.1, y:snakeHead.0), gameBoard: gameBoardMatrixToDictionary(gameBoardMatrix: matrix), returnPathCost: false, returnSquaresVisited: false)
                test = path.0
                pathBlockCordinates = path.1
            } else {
                test = []
            }

            if UserDefaults.standard.bool(forKey: "Step Mode On Setting") {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if let vc = appDelegate.window?.rootViewController {
                    self.viewController = (vc.presentedViewController as? GameScreenViewController)
                    self.viewController?.playButton.setImage(UIImage(named: "Play_Icon_Set"), for: .normal)
                }
                
                UserDefaults.standard.set(true, forKey: "Game Is Paused Setting")
                paused = true
                checkIfPaused()
            }
        }
        // 1 == left, 2 == up, 3 == right, 4 == down
        prevX = Int(minY)
        prevY = Int(minX)
    }
    
    func bringOvermatrix(tempMatrix: [[Int]]) {
        matrix = tempMatrix
    }
    
    func runPredeterminedPath() {
        if gameStarted == true {
            if (test.count != 0) {
                swipe(ID: test[0])
                test.remove(at: 0)
                pathBlockCordinates.remove(at: 0)
                playSound(selectedSoundFileName: "sfx_coin_single3")
                onPathMode = true
            } else {
                onPathMode = false
            }
        }
    }
    
    func update(time: Double) {
        if nextTime == nil {
            nextTime = time + Double(gameSpeed)
        } else if (paused == true) {
//            If the game is paused keep chicking if its paused.
            checkIfPaused()
        }
//        else if (generateVisited == true) {
//            nextTime = time + Double(gameSpeed)
//            print("update hit")
////            colorGameNodes()
////            checkIfPaused()
//        }
        else {
            if time >= nextTime! {
                nextTime = time + Double(gameSpeed)
                
                barrierNodesWaitingToBeDisplayed = Array(Set(barrierNodesWaitingToBeDisplayed).subtracting(barrierNodesWaitingToBeRemoved))
                barrierNodesWaitingToBeRemoved.removeAll()
                
                runPredeterminedPath()
                updateSnakePosition()
                checkIfPaused()
                checkForDeath()
                checkForFoodCollision()
            }
        }
    }
    
    func checkIfPaused() {
        if UserDefaults.standard.bool(forKey: "Game Is Paused Setting") {
            tempColor()
            paused = true
        } else {
            gameSpeed = UserDefaults.standard.float(forKey: "Snake Move Speed")
            paused = false
        }
    }
    
    func tempColor() {
//        for square in game.snakeBodyPos {
//            print(childNode(withName: "//2,2"))
//            square.fillColor = snakeBodySquareColor
//        }
        
        func contains(a:[(Int, Int)], v:(Int,Int)) -> Bool {
            let (c1, c2) = v
            for (v1, v2) in a { if v1 == c1 && v2 == c2 { return true } }
            return false
        }
        
        for (node, x, y) in scene.gameBoard  {
            barrierNodesWaitingToBeDisplayed = Array(Set(barrierNodesWaitingToBeDisplayed).subtracting(barrierNodesWaitingToBeRemoved))
            barrierNodesWaitingToBeRemoved.removeAll()
            
            for i in (barrierNodesWaitingToBeDisplayed) {
                if i.y == y && i.x == x {
                    node.fillColor = scene.barrierSquareColor
//                    node.run(scene.gameSquareAnimation(animation: 2))
                }
            }
            
            for i in (scene.foodPosition) {
                if Int((i.x)) == y && Int((i.y)) == x {
                    node.fillColor = scene.foodSquareColor
//                    node.run(scene.gameSquareAnimation(animation: 2))
                }
            }
            
            if contains(a: snakeBodyPos, v: (x,y)) {
                node.fillColor = scene.snakeBodySquareColor
                if contains(a: [snakeBodyPos.first!], v: (x,y)) {
                    node.fillColor = scene.snakeHeadSquareColor
                }
            }
//            else {
//                node.fillColor = scene.gameboardSquareColor
//            }
        }
    }
    
    func endTheGame() {
        updateScore()
        scene.foodPosition.removeAll()
        snakeBodyPos.removeAll()
    }
    
    // this is run when game hasent started. fix for optimization.
    func checkForDeath() {
        if snakeBodyPos.count > 0 {
            // Create temp variable of snake without the head.
            var snakeBody = snakeBodyPos
            snakeBody.remove(at: 0)
            // Implement wraping snake in god mode.
            // If head is in same position as the body the snake is dead.
            // The snake dies in corners becouse blocks are stacked.
            if contains(a: snakeBody, v: snakeBodyPos[0]) && UserDefaults.standard.integer(forKey: "GodButtonSetting") == 0 {
                endTheGame()
            }
            
            let snakeHead = Tuple(x: snakeBodyPos[0].0, y: snakeBodyPos[0].1)
            if barrierNodesWaitingToBeDisplayed.contains(snakeHead) {
                endTheGame()
            }
        }
    }
    
    func checkForFoodCollision() {
        if scene.foodPosition != nil {
            let x = snakeBodyPos[0].0
            let y = snakeBodyPos[0].1
            var counter = 0
            
            for i in (scene.foodPosition) {
//                if Int((scene.foodPosition?.x)!) == y && Int((scene.foodPosition?.y)!) == x {
                if Int((i.x)) == y && Int((i.y)) == x {
                    if prevX == Int((i.x)) && prevY == Int((i.y)) {
//                        print("closet hit")
                        closetFoodBlockHit = true
                    }
                    
//                    matrix[Int(i.x)][Int(i.y)] = 0
                    matrix[Int(i.y)][Int(i.x)] = 0
                    foodCollisionPoint = counter
                    foodLocationArray.remove(at: foodCollisionPoint)
                    scene.foodPosition.remove(at: foodCollisionPoint)
                    foodDistanceFromHead.remove(at: foodCollisionPoint)
                    
                    
                    spawnFoodBlock()
                    playSound(selectedSoundFileName: "sfx_coin_double3")
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    
                    // Update the score
                    currentScore += 1
                    
                    // Grow snake by 3 blocks.
                    let max = UserDefaults.standard.integer(forKey: "Food Weight Setting")
                    for _ in 1...max {
                        snakeBodyPos.append(snakeBodyPos.last!)
                    }
                }
                counter += 1
            }
         }
    }
    
    func playSound(selectedSoundFileName: String) {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        let musicPath = Bundle.main.path(forResource: selectedSoundFileName, ofType:"wav")!
        let url = URL(fileURLWithPath: musicPath)
        
        if UserDefaults.standard.bool(forKey: "Volume On Setting") {
            do {
                let sound = try AVAudioPlayer(contentsOf: url)
                self.player = sound
                sound.play()
            } catch {
                print("Error playing file")
            }
        }
    }
    
    func swipe(ID: Int) {
//        if onPathMode == false {
//            if !(ID == 2 && playerDirection == 4) && !(ID == 4 && playerDirection == 2) {
//                if !(ID == 1 && playerDirection == 3) && !(ID == 3 && playerDirection == 1) {
                playerDirection = ID
//                }
//            }
//        }
    }
    
    private func updateSnakePosition() {
        var xChange = -1
        var yChange = 0

        switch playerDirection {
            case 1:
                //left
                xChange = -1
                yChange = 0
                break
            case 2:
                //up
                xChange = 0
                yChange = -1
                break
            case 3:
                //right
                xChange = 1
                yChange = 0
                break
            case 4:
                //down
                xChange = 0
                yChange = 1
                break
            default:
                break
        }

        if snakeBodyPos.count > 0 {
            var start = snakeBodyPos.count - 1
            matrix[snakeBodyPos[start].0][snakeBodyPos[start].1] = 0
            while start > 0 {
                snakeBodyPos[start] = snakeBodyPos[start - 1]
                start -= 1
            }
            snakeBodyPos[0] = (snakeBodyPos[0].0 + yChange, snakeBodyPos[0].1 + xChange)
            matrix[snakeBodyPos[0].0][snakeBodyPos[0].1] = 1
            matrix[snakeBodyPos[1].0][snakeBodyPos[1].1] = 1
            matrix[snakeBodyPos[2].0][snakeBodyPos[2].1] = 1
//            for i in 0...14 {
//                print(matrix[i])
//            }
//            print("----")
        }
        
        if snakeBodyPos.count > 0 {
            let x = snakeBodyPos[0].1
            let y = snakeBodyPos[0].0
            if y > 15 {
                snakeBodyPos[0].0 = 0
            } else if y < 0 {
                snakeBodyPos[0].0 = 15
            } else if x > 15 {
                snakeBodyPos[0].1 = 0
            } else if x < 0 {
                snakeBodyPos[0].1 = 15
            }
        }
        colorGameNodes()
    }
    
    func colorGameNodes() {
        for (node, x, y) in scene.gameBoard {
            
            if contains(a: snakeBodyPos, v: (x,y)) {
                if (onPathMode == false) {
                    node.fillColor = SKColor.white
//                    node.run(scene.gameSquareAnimation())
//                    node.run(scene.gameSquareAnimation(animation: 2))
                }
            }
            
            for i in (pathBlockCordinates) {
                if Int((i.0)) == y && Int((i.1)) == x {
                    node.fillColor = scene.pathSquareColor
                }
            }
            
            // add closest food to legend
            if contains(a: snakeBodyPos, v: (x,y)) {
                if (onPathMode == true) {
                    node.fillColor = scene.snakeBodySquareColor
                    if contains(a: [snakeBodyPos.first!], v: (x,y)) {
                        node.fillColor = scene.snakeHeadSquareColor
//                        node.run(scene.gameSquareAnimation(animation: 2))
//                        colorVisitedSquares(visited: [Tuple(x: x, y: y)])
                    }
                }
            }
            
            else {
                // error loading colors on first lanch for food pellet.
                // error snake speed on first load.
                // paused is broken
                node.fillColor = scene.gameboardSquareColor
                if scene.foodPosition.isEmpty != true {
                    
                    for i in (scene.foodPosition) {
                        if Int((i.x)) == y && Int((i.y)) == x {
                            node.fillColor = scene.foodSquareColor
//                            node.run(scene.gameSquareAnimation(animation: 2))
                        }
                    }
                    
                    for i in (barrierNodesWaitingToBeDisplayed) {
                        if i.y == y && i.x == x {
                            node.fillColor = scene.barrierSquareColor
//                           node.run(scene.gameSquareAnimation(animation: 2))
                        }
                    }
                    
                    
                    // if this works its more effietient.
                    //            if onPathMode == true {
                    //                if contains(a: pathBlockCordinates, v: (x,y)) {
                    //                    node.fillColor = UserDefaults.standard.colorForKey(key: "Path")!
                    //                }
                    //            }
                    
                    for i in (pathBlockCordinates) {
                        if Int((i.0)) == y && Int((i.1)) == x {
//                            print("-")
                            node.fillColor = scene.pathSquareColor
                        }
                    }
                }
            }
        }
    }
    
    func contains(a:[(Int, Int)], v:(Int,Int)) -> Bool {
        let (c1, c2) = v
        for (v1, v2) in a { if v1 == c1 && v2 == c2 { return true } }
        return false
    }

    func updateScore() {
        // Update the high score if need be.
         if currentScore > UserDefaults.standard.integer(forKey: "highScore") {
              UserDefaults.standard.set(currentScore, forKey: "highScore")
         }
        
        // Reset and present score variables on game menu.
        UserDefaults.standard.set(currentScore, forKey: "lastScore")
         currentScore = 0
//         scene.highScore.text = "High Score: \(UserDefaults.standard.integer(forKey: "highScore"))"
    }
}
