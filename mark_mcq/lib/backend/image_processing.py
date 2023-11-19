from flask import Flask, request, jsonify
import cv2
import numpy as np
import os

app = Flask(__name__)

@app.route('/process_folder', methods=['POST'])
def process_folder():
    data = request.json  # Receive JSON data with the folder path
    folder_path = data['folder_path']
    paper_type = data['paper_type_index']
    correct_answers = data['answer_list']
    print("you are in python file")

    for i in range(len(correct_answers)):
        correct_answers[i] -= 1

    if not folder_path:
        return jsonify({"error": "Folder path not provided"})

    if not os.path.exists(folder_path):
        return jsonify({"error": "Folder not found"})

    scores = []

    for filename in os.listdir(folder_path):
        if filename.endswith(".jpg") or filename.endswith(".png"):
            image_path = os.path.join(folder_path, filename)

            # Call the existing image processing function
            if paper_type==0:
                result = process_image_1col(image_path,correct_answers)
            elif paper_type==1:
                result= process_image_4col(image_path,correct_answers)
            elif paper_type==2:
                result = process_image_2col(image_path,correct_answers)

            # Append image name and total score to the scores list
            scores.append({"imageName": filename, "totalScore": result["TotalScore"]})

    return jsonify(scores)

def process_image_1col(image_path,correct_answers):
    if not image_path:
        return jsonify({"error": "Image path not provided"})

    if not os.path.exists(image_path):
        return jsonify({"error": "Image file not found"})
    
    ####parameters
    path = "1Col.jpg"
    widthImg = 230
    heightImg = 800
    questions = 25
    choices = 5
    ####

    ##functions
    def rectangleContour(countours):
        rectCon = []
        for i in countours:
            area = cv2.contourArea(i)

            if area > 50:
                peri = cv2.arcLength(i, True)
                approx = cv2.approxPolyDP(i, 0.02 * peri, True)

                if len(approx) == 4:
                    rectCon.append(i)

        rectCon = sorted(rectCon, key=cv2.contourArea, reverse=True)
        # sort 4 corner polygon based on area

        return rectCon
        # rectCon is a list that contains all the 4 corner contours starting from the largest one


    def getCornerPoints(cont):
        peri = cv2.arcLength(cont, True)
        approx = cv2.approxPolyDP(cont, 0.02 * peri, True)
        return approx


    # function to re order points to identify origin and other points in biggest rectangle
    def reorder(myPoints):
        myPoints = myPoints.reshape(
            (4, 2)
        )  # change biggest contour list to 4 by 2 list/array of points
        # 4 - 4 rows or points
        # 2 - each point has 2 values (x , y)

        # add and substract to find origin points and diagonal points and other 2 corner points
        myPointsNew = np.zeros((4, 1, 2), np.int32)
        add = myPoints.sum(1)

        myPointsNew[0] = myPoints[np.argmin(add)]
        myPointsNew[3] = myPoints[np.argmax(add)]
        diff = np.diff(myPoints, axis=1)
        myPointsNew[1] = myPoints[np.argmin(diff)]  # [w , 0]
        myPointsNew[2] = myPoints[np.argmax(diff)]  # [h , 0]

        return myPointsNew


    def splitBoxes(img):
        # split img horizontally to get rows
        rows = np.vsplit(img, 25)
        boxes = []

        for r in rows:
            cols = np.hsplit(r, 5)
            for box in cols:
                boxes.append(box)

        return boxes


    # function to mark correct answers in the answer sheet
    def markAnswersFunction(img, myIndex, grading, ans, questions, choices):
        secW = int(img.shape[1] / choices)
        secH = int(img.shape[0] / questions)

        for x in range(25):
            myAns = myIndex[x]
            cX = (myAns * secW) + secW // 2
            cY = (x * secH) + secH // 2

            if grading[x] == 1:
                myColor = (0, 255, 0)
            else:
                myColor = (0, 0, 255)
                correctAns = ans[x]
                cv2.circle(
                    img,
                    ((correctAns * secW) + secW // 2, (x * secH) + secH // 2),
                    10,
                    (0, 255, 0),
                    cv2.FILLED,
                )

            cv2.circle(img, (cX, cY), 10, myColor, cv2.FILLED)

        return img


    ##

    ###
    # ORIGINAL ANSWERS
    ans = correct_answers

    # assigning path to a variables
    img = cv2.imread(image_path)

    # IMAGE PREPROCESSING

    # resize image
    img = cv2.resize(img, (widthImg, heightImg))

    # new image
    imgContours = img.copy()
    imgBiggestContours = img.copy()

    # convert to grey scale
    imgGrey = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # add blur
    imgBlur = cv2.GaussianBlur(imgGrey, (5, 5), 1)
    # size of kernel is 5*5
    # zigma-x value = 1

    # detect edges using img scan function
    # Finding the edges of the image
    imgCanny = cv2.Canny(imgBlur, 10, 50)
    # 10 and 50 are threshold values
    # using canny edge detector we detect rectangles that we need for marking.


    # FINDING ALL CONTOURS
    # find contours - continuous curves or outlines that represent the
    # boundaries of objects or regions in an image
    countours, hierarchy = cv2.findContours(
        imgCanny, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE
    )
    # use external method - this helps to find outer edges
    # no need of approximations

    # to draw contours
    cv2.drawContours(imgContours, countours, -1, (0, 255, 0), 10)

    # FIND RECTANGLES
    rectCon = rectangleContour(countours)
    # rectCon is a list with all the 4 sided contours starting from largest one

    biggestContour = getCornerPoints(rectCon[0])
    # take the 4 corner points of biggest rectangle

    if biggestContour.size != 0:
        cv2.drawContours(
            imgBiggestContours, biggestContour, -1, (0, 255, 0), 20
        )  # draw biggest contour

        biggestContour = reorder(biggestContour)
        # reorder points to identify origin and 1st one etc

        pt1 = np.float32(biggestContour)
        pt2 = np.float32([[0, 0], [widthImg, 0], [0, heightImg], [widthImg, heightImg]])
        matrix = cv2.getPerspectiveTransform(pt1, pt2)
        imgWarpColoured = cv2.warpPerspective(img, matrix, (widthImg, heightImg))

        # find marked answers
        # marked answer bubbles have higher pexels than normal bubbles
        # APPLY THRESOLD to find marking points
        # convert img to grey
        imgwrapGray = cv2.cvtColor(imgWarpColoured, cv2.COLOR_BGR2GRAY)
        # apply thresold
        imgThresh = cv2.threshold(imgwrapGray, 100, 250, cv2.THRESH_BINARY_INV)[1]

        # take each bubble and see how many pexel values are non-zero to find which is marked
        # devide image to a grid where each grid has one bubble
        # as here we have 5*5 bubbles split img to 25 regions

        boxes = splitBoxes(imgThresh)

        # Getting non-zero pexel values of each box
        myPixelVal = np.zeros((questions, choices))
        countCol = 0
        countRow = 0

        for image in boxes:
            totalPixels = cv2.countNonZero(image)
            myPixelVal[countRow][countCol] = totalPixels
            countCol += 1
            if countCol == choices:
                countRow += 1
                countCol = 0

        # print(myPixelVal)

        # Finding index values of markings
        myIndex = []
        for x in range(0, questions):
            arr = myPixelVal[x]
            myIndexVal = np.where(arr == np.amax(arr))

            myIndex.append(myIndexVal[0][0])

        # Grade the paper
        grading = []
        grade = 0
        for i in range(0, questions):
            if ans[i] == myIndex[i]:
                grading.append(1)
                grade += 1
            else:
                grading.append(0)
                grade += 0

        finalScore = (sum(grading) / questions) * 100

        print("Final Marks =", finalScore)

        # mark correct and wrong answers in the answer sheet
        imgResult = imgWarpColoured.copy()
        imgResult = markAnswersFunction(
            imgResult, myIndex, grading, ans, questions, choices
        )

        cv2.imshow("Markings ", imgResult)


    cv2.waitKey(0)

def process_image_4col(image_path,correct_answers):
    # data = request.json  # Receive JSON data with the image path
    # pathOfImage = data['image_path']
    
    if not image_path:
        return jsonify({"error": "Image path not provided"})

    if not os.path.exists(image_path):
        return jsonify({"error": "Image file not found"})

    ####parameters
    widthImage = 600
    heightImage = 800
    questionsPerCol = 10
    choices = 5
    ####

    # functions

    rowNumber = 10
    colNumber = 5


    def rectContours(countours):
        # filter using area
        # loop through all contours and filter area
        rectCon = []

        for i in countours:
            area = cv2.contourArea(i)

            if area > 500:
                peri = cv2.arcLength(i, True)
                approx = cv2.approxPolyDP(i, 0.02 * peri, True)

                if len(approx) == 4:
                    rectCon.append(i)
        rectCon = sorted(rectCon, key=cv2.contourArea, reverse=True)

        return rectCon


    def getCornerPoints(cont):
        peri = cv2.arcLength(cont, True)
        approx = cv2.approxPolyDP(cont, 0.02 * peri, True)
        return approx


    def reorder(myPoints):
        myPoints = myPoints.reshape((4, 2))
        myPointsNew = np.zeros((4, 1, 2), np.int32)
        add = myPoints.sum(1)

        myPointsNew[0] = myPoints[np.argmin(add)]
        myPointsNew[3] = myPoints[np.argmax(add)]
        diff = np.diff(myPoints, axis=1)
        myPointsNew[1] = myPoints[np.argmin(diff)]
        myPointsNew[2] = myPoints[np.argmax(diff)]

        return myPointsNew


    # function to devide each answer column to a grdi to extract each individual bubble.
    def splitFunction(image):
        # 1st split horizontally to get all the rows
        rows = np.vsplit(image, rowNumber)
        bubbleArray = []

        # split vertically to get individual bubbles
        for r in rows:
            columns = np.hsplit(r, colNumber)

            for bubble in columns:
                bubbleArray.append(bubble)

        return bubbleArray


    ##end of function

    ###
    # ORIGINAL ANSWERS
    ansCol1 = correct_answers[0:10]  # answers for column 1
    ansCol2 = correct_answers[10:20]  # answers for column 2
    ansCol3 = correct_answers[20:30]  # answers for column 3
    ansCol4 = correct_answers[30:40]   # answers for column 4
    print("seperated columns")
    print(ansCol1)
    print(ansCol2)
    print(ansCol3)
    print(ansCol4)
    print("seperated columns")

    # assigning path to a variables
    img = cv2.imread(image_path)

    # IMAGE PREPROCESSING STEPS

    # 1) resize image
    img = cv2.resize(img, (widthImage, heightImage))

    # new image
    # take a copy of original image to draw contours and mark biggest contours
    imageContours = img.copy()
    imgBiggestContours = img.copy()

    # convert image to grey scale
    imageGrey = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # add blur to grey scale image
    imageBlur = cv2.GaussianBlur(imageGrey, (5, 5), 1)
    # size of kernel is 5*5
    # zigma-x value = 1

    # detect edges using imgcanny function
    # Finding the edges of the image
    imageCanny = cv2.Canny(imageBlur, 10, 50)
    # 10 and 50 are threshold values
    # using canny edge detector we detect rectangles that we need for marking.


    # FINDING ALL CONTOURS
    # contours - continuous curves or outlines that represent boundaries of objects or regions in an image
    countours, hierarchy = cv2.findContours(
        imageCanny, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE
    )
    # use external method - this helps to find outer edges
    # no need of approximations

    # draw detected contours on a new copy of image
    cv2.drawContours(imageContours, countours, -1, (0, 255, 0), 10)

    # find rectangles
    rectangleContours = rectContours(countours)
    # rectangleContours is a list which stores rectangle in area descending order

    biggestContour1 = getCornerPoints(rectangleContours[0])
    biggestContour2 = getCornerPoints(rectangleContours[1])
    biggestContour3 = getCornerPoints(rectangleContours[2])
    biggestContour4 = getCornerPoints(rectangleContours[3])
    # devide 4 column answer sheet to 4 parts.
    # each column is taken as a seperate rectangle and indexed them from 1 to 4 starting from left most one

    # check weather detected rectangles actually consists of an area
    if (
        biggestContour1.size != 0
        and biggestContour2.size != 0
        and biggestContour3.size != 0
        and biggestContour4.size != 0
    ):
        # draw the 4 biggest contours in new copy of original iamge
        cv2.drawContours(imgBiggestContours, biggestContour1, -1, (0, 255, 0), 10)
        cv2.drawContours(imgBiggestContours, biggestContour2, -1, (255, 0, 0), 10)
        cv2.drawContours(imgBiggestContours, biggestContour3, -1, (225, 255, 0), 10)
        cv2.drawContours(imgBiggestContours, biggestContour4, -1, (200, 200, 200), 10)

        # reorder 4 corner points of each detected rectangle to find exact 4 corner points in correct order in anticlock wise direction
        biggestContour1 = reorder(biggestContour1)
        biggestContour2 = reorder(biggestContour2)
        biggestContour3 = reorder(biggestContour3)
        biggestContour4 = reorder(biggestContour4)

        # as image capturing can be done in several angles apply werp perspective to get bird eye view

        point1 = np.float32(biggestContour1)
        point2 = np.float32(
            [[0, 0], [widthImage, 0], [0, heightImage], [widthImage, heightImage]]
        )
        matrix1 = cv2.getPerspectiveTransform(point1, point2)
        image1Warp = cv2.warpPerspective(img, matrix1, (widthImage, heightImage))

        point3 = np.float32(biggestContour2)
        point4 = np.float32(
            [[0, 0], [widthImage, 0], [0, heightImage], [widthImage, heightImage]]
        )
        matrix2 = cv2.getPerspectiveTransform(point3, point4)
        image2Warp = cv2.warpPerspective(img, matrix2, (widthImage, heightImage))

        point5 = np.float32(biggestContour3)
        point6 = np.float32(
            [[0, 0], [widthImage, 0], [0, heightImage], [widthImage, heightImage]]
        )
        matrix3 = cv2.getPerspectiveTransform(point5, point6)
        image3Warp = cv2.warpPerspective(img, matrix3, (widthImage, heightImage))

        point7 = np.float32(biggestContour4)
        point8 = np.float32(
            [[0, 0], [widthImage, 0], [0, heightImage], [widthImage, heightImage]]
        )
        matrix4 = cv2.getPerspectiveTransform(point7, point8)
        image4Warp = cv2.warpPerspective(img, matrix4, (widthImage, heightImage))

        # convert to grey scale
        image1WarpGrey = cv2.cvtColor(image1Warp, cv2.COLOR_BGR2GRAY)
        image2WarpGrey = cv2.cvtColor(image2Warp, cv2.COLOR_BGR2GRAY)
        image3WarpGrey = cv2.cvtColor(image3Warp, cv2.COLOR_BGR2GRAY)
        image4WarpGrey = cv2.cvtColor(image4Warp, cv2.COLOR_BGR2GRAY)

        image1Thresh = cv2.threshold(image1WarpGrey, 180, 300, cv2.THRESH_BINARY_INV)[1]
        image2Thresh = cv2.threshold(image2WarpGrey, 180, 300, cv2.THRESH_BINARY_INV)[1]
        image3Thresh = cv2.threshold(image3WarpGrey, 180, 300, cv2.THRESH_BINARY_INV)[1]
        image4Thresh = cv2.threshold(image4WarpGrey, 180, 300, cv2.THRESH_BINARY_INV)[1]

        # take each individual bubbles and find pixel values of each bubble to find marked bubbles

        # 1st split each image to 50 sections
        bubbleList1 = splitFunction(image1Thresh)
        bubbleList2 = splitFunction(image2Thresh)
        bubbleList3 = splitFunction(image3Thresh)
        bubbleList4 = splitFunction(image4Thresh)

        # getting non-zero pexel values of each bubble

        # create 4 empty arrays to store marked bubbles of each answer
        PixelArray1 = np.zeros((questionsPerCol, choices))
        PixelArray2 = np.zeros((questionsPerCol, choices))
        PixelArray3 = np.zeros((questionsPerCol, choices))
        PixelArray4 = np.zeros((questionsPerCol, choices))

        # getting non-zero pexel values of each bubble

        countColumn1 = 0
        countRow1 = 0

        for bubble1 in bubbleList1:
            totalPixels1 = cv2.countNonZero(bubble1)

            # store these in array
            PixelArray1[countRow1][countColumn1] = totalPixels1
            countColumn1 += 1
            if countColumn1 == choices:
                countRow1 += 1
                countColumn1 = 0

        # for 2nd image
        countColumn2 = 0
        countRow2 = 0

        for image2 in bubbleList2:
            totalPixels2 = cv2.countNonZero(image2)
            PixelArray2[countRow2][countColumn2] = totalPixels2
            countColumn2 += 1
            if countColumn2 == choices:
                countRow2 += 1
                countColumn2 = 0

        # for 3rd image
        countColumn3 = 0
        countRow3 = 0

        for image3 in bubbleList3:
            totalPixels3 = cv2.countNonZero(image3)
            PixelArray3[countRow3][countColumn3] = totalPixels3
            countColumn3 += 1
            if countColumn3 == choices:
                countRow3 += 1
                countColumn3 = 0

        # for 4th image
        countColumn4 = 0
        countRow4 = 0

        for image4 in bubbleList4:
            totalPixels4 = cv2.countNonZero(image4)
            PixelArray4[countRow4][countColumn4] = totalPixels4
            countColumn4 += 1
            if countColumn4 == choices:
                countRow4 += 1
                countColumn4 = 0

        # finding index values of markings

        Index1 = []
        Index2 = []
        Index3 = []
        Index4 = []

        for x in range(0, questionsPerCol):
            arr1 = PixelArray1[x]
            arr2 = PixelArray2[x]
            arr3 = PixelArray3[x]
            arr4 = PixelArray4[x]

            myIndexVal1 = np.where(arr1 == np.amax(arr1))
            myIndexVal2 = np.where(arr2 == np.amax(arr2))
            myIndexVal3 = np.where(arr3 == np.amax(arr3))
            myIndexVal4 = np.where(arr4 == np.amax(arr4))

            Index1.append(myIndexVal1[0][0])
            Index2.append(myIndexVal2[0][0])
            Index3.append(myIndexVal3[0][0])
            Index4.append(myIndexVal4[0][0])

        # grading
        grading1 = []
        grading2 = []
        grading3 = []
        grading4 = []

        for x in range(0, questionsPerCol):
            if ansCol1[x] == Index1[x]:
                grading1.append(1)
            else:
                grading1.append(0)

        for y in range(0, questionsPerCol):
            if ansCol2[y] == Index2[y]:
                grading2.append(1)
            else:
                grading2.append(0)

        for z in range(0, questionsPerCol):
            if ansCol3[z] == Index3[z]:
                grading3.append(1)
            else:
                grading3.append(0)

        for k in range(0, questionsPerCol):
            if ansCol4[k] == Index4[k]:
                grading4.append(1)
            else:
                grading4.append(0)

        # final score
        score1 = sum(grading1)
        score2 = sum(grading2)
        score3 = sum(grading3)
        score4 = sum(grading4)

        #TotalScore = (score1 + score2 + score3 + score4) / (questionsPerCol * 4) * 100
        TotalScore = (score1+score2+ score3 + score4)
        #/(questionsPerCol*4)*100

        result = {
            "TotalScore": TotalScore
        }

        return result

def process_image_2col(image_path,correct_answers):
    ####parameters
    pathOfImage = "2col.jpg"
    widthImage = 300
    heightImg = 700
    questionsPercol = 25
    choices = 5
    ####

    ####function###

    rowNumber = 25
    colNumber = 5

    def FindRectangleContours(countours):
        #filter using area
        #loop through all contours and filter area
        rectangleCon = []

        for i in countours:
            area = cv2.contourArea(i)

            if area>6000:
                perimeter = cv2.arcLength(i , True)
                approximation = cv2.approxPolyDP(i , 0.02*perimeter , True)

                if len(approximation) == 4:
                    rectangleCon.append(i)
        rectangleCon = sorted(rectangleCon , key = cv2.contourArea , reverse = True)

        return rectangleCon

    def FindCornerPointsFunction(cont):
        perimeters = cv2.arcLength(cont , True)
        approximation = cv2.approxPolyDP(cont , 0.02*perimeters , True)
        return approximation

    def reorderPointsFunction(Points):
        Points = Points.reshape((4,2))
        PointsNew = np.zeros((4,1,2) , np.int32)
        add = Points.sum(1)

        PointsNew[0] = Points[np.argmin(add)]
        PointsNew[3] = Points[np.argmax(add)]
        diff = np.diff(Points , axis = 1)
        PointsNew[1] = Points[np.argmin(diff)]
        PointsNew[2] = Points[np.argmax(diff)]
        
        return PointsNew

    def splitFunction(image):
        #1st split horizontally to get all the rows
        rows = np.vsplit(image,rowNumber)
        bubbleArray = []
        
        #split vertically to get individual bubbles
        for r in rows:
            columns = np.hsplit(r,colNumber)

            for bubble in columns:
                bubbleArray.append(bubble)

        return bubbleArray

    ####end of function####

    ###
    # ORIGINAL ANSWERS
    ansCol1 = correct_answers[0:25]#answers for column 1
    ansCol2 = correct_answers[25:]#answers for column 2

    # assigning path to a variables
    img = cv2.imread(image_path)

    # IMAGE PREPROCESSING

    # resize image
    img = cv2.resize(img, (widthImage, heightImg))

    # new image
    #take a copy of original image to draw contours and mark biggest contours
    imageContours = img.copy()
    imgBiggestContours = img.copy()

    # convert to grey scale
    imageGrey = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # add blur
    imageBlur = cv2.GaussianBlur(imageGrey, (5, 5), 1)
    # size of kernel is 5*5
    # zigma-x value = 1

    # detect edges using img canny function
    # Finding the edges of the image
    imageCanny = cv2.Canny(imageBlur, 10, 50)
    # 10 and 50 are threshold values
    # using canny edge detector we detect rectangles that we need for marking.


    # FINDING ALL CONTOURS
    # find contours - continuous curves or outlines that represent the
    # boundaries of objects or regions in an image
    countours, hierarchy = cv2.findContours(imageCanny, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    # use external method - this helps to find outer edges
    # no need of approximations

    #draw detected contours on a new copy of image
    cv2.drawContours(imageContours , countours , -1 , (0,255,0) , 1)

    #find rectangles
    rectangleContours = FindRectangleContours(countours)
    #rectangleContours is a list which stores rectangle in area descending order
    biggestContour1 = FindCornerPointsFunction(rectangleContours[0])
    biggestContour2 = FindCornerPointsFunction(rectangleContours[1])

    #check weather detected rectangles actually consists of an area
    if biggestContour1.size != 0 and biggestContour2.size != 0:
        cv2.drawContours(imgBiggestContours , biggestContour1 ,-1, (0,255,0) , 10)
        cv2.drawContours(imgBiggestContours , biggestContour2 ,-1, (255,0,0) , 10)

        #reorder 4 corner points of each detected rectangle to find exact 4 corner points in correct order in anticlock wise direction
        biggestContour1 = reorderPointsFunction(biggestContour1)
        biggestContour2 = reorderPointsFunction(biggestContour2)

        #as image capturing can be done in several angles apply werp perspective to get bird eye view
        #apply werp perspective for biggestContour1 to get bird eye view
        point1 = np.float32(biggestContour1)
        point2 = np.float32([[0,0] , [widthImage,0] , [0, heightImg] , [widthImage,heightImg]])
        matrix1 = cv2.getPerspectiveTransform(point1 , point2)
        image1Warp = cv2.warpPerspective(img , matrix1 , (widthImage , heightImg))

        #apply werp perspective for biggestContour2 to get bird eye view
        point3 = np.float32(biggestContour2)
        point4 = np.float32([[0,0] , [widthImage,0] , [0, heightImg] , [widthImage,heightImg]])
        matrix2 = cv2.getPerspectiveTransform(point3 , point4)
        image2Warp = cv2.warpPerspective(img , matrix2 , (widthImage , heightImg))

        #apply threshold 
        image1WarpGrey = cv2.cvtColor(image1Warp , cv2.COLOR_BGR2GRAY)
        image2WarpGrey = cv2.cvtColor(image2Warp , cv2.COLOR_BGR2GRAY)

        image1Thresh = cv2.threshold(image1WarpGrey , 130 , 300 , cv2.THRESH_BINARY_INV)[1]
        image2Thresh = cv2.threshold(image2WarpGrey , 130 , 300 , cv2.THRESH_BINARY_INV)[1]

        #take each individual bubbles and find pixel values of each bubble to find marked bubbles

        #1st split each image to 25 by 5 sections
        bubbleList1 = splitFunction(image1Thresh)
        bubbleList2 = splitFunction(image2Thresh)

        #getting non-zero pexel values of each box 

        #create 2 empty arrays to store marked bubbles of each answer
        PixelArray1 = np.zeros((questionsPercol,choices))
        PixelArray2 = np.zeros((questionsPercol,choices))

        countColumn1 = 0
        countRow1 = 0

        for bubble1 in bubbleList1:
            totalPixels1 = cv2.countNonZero(bubble1)
            PixelArray1[countRow1][countColumn1] = totalPixels1
            countColumn1 += 1
            if (countColumn1 == choices):
                countRow1 += 1
                countColumn1= 0;

        #for 2nd image
        countColumn2 = 0
        countRow2 = 0

        for bubble2 in bubbleList2:
            totalPixels2 = cv2.countNonZero(bubble2)
            PixelArray2[countRow2][countColumn2] = totalPixels2
            countColumn2 += 1
            if (countColumn2 == choices):
                countRow2 += 1
                countColumn2= 0;
        
        #finding index values of markings

        Index1 = []
        Index2 = []

        for x in range (0,questionsPercol):
            arr1 = PixelArray1[x]
            arr2 = PixelArray2[x]

            Ival1 = np.where(arr1 == np.amax(arr1))
            Ival2 = np.where(arr2 == np.amax(arr2))
            
            Index1.append(Ival1[0][0])
            Index2.append(Ival2[0][0])


        #grading
        marks1 = []
        marks2 = []

        for x in range (0,questionsPercol):
            if ansCol1[x] == Index1[x]:
                marks1.append(1)
            else:
                marks1.append(0)

        for y in range(0 , questionsPercol):
            if ansCol2[y] == Index2[y]:
                marks2.append(1)
            else:
                marks2.append(0)
        
        #final score
        score1 = sum(marks1)
        score2 = sum(marks2)
        TotalScore = (score1+score2)/(questionsPercol*2)*100

        print("Final Marks = " , TotalScore)

    cv2.waitKey(0)    

if __name__ == '__main__':
    app.run(debug=True)
