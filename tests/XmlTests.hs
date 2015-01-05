{-# LANGUAGE OverloadedStrings #-}

module Main where

import Blaze.ByteString.Builder
import qualified Data.ByteString.Lazy.Char8 as BSL8
import Data.Map
import Data.Maybe
import Data.OpenSRS.ToXML
import Data.OpenSRS.Types
import Data.Time
import Test.Hspec
import Text.XmlHtml

-- | API configuration to use in these (non-integration) tests.
testConfig :: SRSConfig
testConfig = SRSConfig "https://horizon.opensrs.net:55443" "janedoe" "0123456789abcdef" "127.0.0.1" True

testDomain1 :: IO Domain
testDomain1 = do
    t <- getCurrentTime
    let t' = addUTCTime ((86400 * 365) :: NominalDiffTime) t
    return $ Domain "foo.com" True contacts (Just t) True (Just t) (Just "5534") True (Just t') nameservers
  where
    contacts = fromList [
        ("owner", testc),
        ("admin", testc),
        ("billing", testc),
        ("tech", testc)
        ]
    testc = Contact (Just "Jane")
                    (Just "Doe")
                    (Just "Frobozz Pty Ltd")
                    (Just "jane.doe@frobozz.com.au")
                    (Just "+61.299999999")
                    Nothing
                    (Just "Frobozz Pty Ltd")
                    (Just "Level 50")
                    (Just "1 George Street")
                    (Just "Sydney")
                    (Just "NSW")
                    (Just "2000")
                    (Just "AU")
    nameservers = [
        Nameserver (Just "ns1.anchor.net.au") (Just "0") (Just "127.0.0.1"),
        Nameserver (Just "ns2.anchor.net.au") (Just "0") (Just "127.0.0.2") ]

reqXML :: SRSRequest -> String
reqXML = BSL8.unpack . toLazyByteString . render . requestXML

suite :: Spec
suite =
    describe "Domains" $ do
        it "Can be marshalled into a registration request" $ do
            d <- testDomain1
            let req = RegisterDomain testConfig d False Nothing Nothing
                                     False False True True 1
                                     (fromJust $ makeUsername "janedoe")
                                     (fromJust $ makePassword "imasecret")
                                     NewRegistration Nothing
            let rxml = reqXML req
            rxml `shouldContain` "<OPS_envelope>"

        it "Can be marshalled into an update request" $ do
            d <- testDomain1
            let req = UpdateDomain testConfig d
            let rxml = reqXML req
            rxml `shouldContain` "<OPS_envelope>"

main :: IO ()
main = hspec suite
