import SwiftUI
import Testing
@testable import Motiva

struct SVGPathTests {
    @Test func absoluteLines() {
        #expect(SVGPath.parse("M0 0L10 0L10 10Z").boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func relativeCommandsAndHorizontalVerticalLines() {
        #expect(SVGPath.parse("m5 5l10 0v10h-10z").boundingRect == CGRect(x: 5, y: 5, width: 10, height: 10))
    }

    @Test func extraPairsAfterMoveAreLines() {
        #expect(SVGPath.parse("M0 0 10 0 10 10").boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func numbersWithoutSeparators() {
        #expect(SVGPath.parse("M0-5L10-5").boundingRect == CGRect(x: 0, y: -5, width: 10, height: 0))
        #expect(SVGPath.parse("M.5.5L1.5 1.5").boundingRect == CGRect(x: 0.5, y: 0.5, width: 1, height: 1))
        #expect(SVGPath.parse("M1e1 0L2e1 0").boundingRect == CGRect(x: 10, y: 0, width: 10, height: 0))
    }

    @Test func smoothCurveReflectsThePreviousControlPoint() {
        let smooth = SVGPath.parse("M0 0C0 10 10 10 10 0S20 -10 20 0")
        let explicit = SVGPath.parse("M0 0C0 10 10 10 10 0C10 -10 20 -10 20 0")
        #expect(smooth == explicit)
    }

    @Test func repeatedRelativeCurvesContinueFromTheLastPoint() {
        let repeated = SVGPath.parse("M0 0c0 5 5 5 5 0 0 5 5 5 5 0")
        let explicit = SVGPath.parse("M0 0C0 5 5 5 5 0C5 5 10 5 10 0")
        #expect(repeated == explicit)
    }

    @Test func secondSubpathAfterCloseStartsFromTheFirstStart() {
        let path = SVGPath.parse("M10 10h5v5zm20 0h5v5z")
        #expect(path.boundingRect == CGRect(x: 10, y: 10, width: 25, height: 5))
    }

    @Test func shapeScalesTheViewBoxToFit() {
        let shape = SVGShape("M0 0H10V10H0Z", viewBox: CGSize(width: 10, height: 10))
        #expect(shape.path(in: CGRect(x: 0, y: 0, width: 100, height: 50)).boundingRect == CGRect(x: 25, y: 0, width: 50, height: 50))
    }

    @Test func shapeHonoursAViewBoxOrigin() {
        let shape = SVGShape("M50 50H60V60H50Z", viewBox: CGRect(x: 50, y: 50, width: 10, height: 10))
        #expect(shape.path(in: CGRect(x: 0, y: 0, width: 20, height: 20)).boundingRect == CGRect(x: 0, y: 0, width: 20, height: 20))
    }
}

struct QuoteLibraryTests {
    @Test func everyTopicHasQuotes() {
        for topic in QuoteLibrary.topics {
            #expect(!topic.quotes.isEmpty, "\(topic.name) has no quotes")
        }
    }

    @Test func forYouContainsEveryQuoteExactlyOnce() {
        let all = QuoteLibrary.featured + QuoteLibrary.topics.flatMap(\.quotes)
        #expect(QuoteLibrary.forYou.count == all.count)
        #expect(Set(QuoteLibrary.forYou).count == QuoteLibrary.forYou.count, "Duplicate quote in library")
    }

    @Test func unknownTopicFallsBackToForYou() {
        #expect(QuoteLibrary.quotes(for: "Not a topic") == QuoteLibrary.forYou)
        #expect(QuoteLibrary.quotes(for: nil) == QuoteLibrary.forYou)
        #expect(QuoteLibrary.quotes(for: "Confidence") == QuoteLibrary.topics.first { $0.name == "Confidence" }?.quotes)
    }
}
